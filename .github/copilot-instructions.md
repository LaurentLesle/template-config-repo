# Copilot Instructions — Infrastructure Configuration Repository

## Purpose

This repository contains **YAML configuration files only**. It does NOT contain Terraform modules or HCL code.
Infrastructure is defined in `configurations/env-{environment}/config.yaml` files, which are processed by the
upstream module repository [LaurentLesle/terraform-rest-galaxy](https://github.com/LaurentLesle/terraform-rest-galaxy).

## Config File Location

Environments are auto-discovered from `configurations/env-{name}/config.yaml`.
Add or remove directories to change which environments are deployed — no workflow edits needed.

Examples:
- `configurations/env-dev/config.yaml`
- `configurations/env-prod/config.yaml`
- `configurations/env-global/config.yaml`

## YAML Config Schema

Every config file has this structure:

```yaml
# Required — Terraform state backend
terraform_backend:
  type: azurerm                              # azurerm | local
  storage_account_name: <name>
  container_name: <name>
  key: <org>/<env>/<region>/<workload>/terraform.tfstate
  resource_group_name: <name>

# Required — target subscription (existing subscription to deploy INTO, not for creating new ones)
subscription_id: "<guid>"

# Optional — default location for all resources
default_location: westeurope

# Resources — each key maps to an upstream Terraform module
azure_resource_groups:
  <logical_key>:
    resource_group_name: rg-...
    location: westeurope
    tags:
      environment: dev
```

## State Key Naming Convention

Format: `<org>/<env>/<region>/<workload>/terraform.tfstate`
- All segments lowercase, no spaces
- Example: `acme/dev/westeurope/core-infra/terraform.tfstate`

## Cross-Resource References (`ref:`)

Use `ref:` to reference outputs from other resources in the same config:

```yaml
azure_storage_accounts:
  data:
    resource_group_name: ref:azure_resource_groups.core.resource_group_name
    location: ref:azure_resource_groups.core.location
    tags: ref:azure_resource_groups.core.tags
```

Reference format: `ref:<config_key>.<logical_key>.<attribute>`

Special references:
- `ref:caller.object_id` — the current user/service principal object ID
- `ref:externals.<type>.<key>.<attribute>` — external (non-managed) resources
- `ref:remote_states.<key>.<path>` — cross-stack remote state outputs (see "Consuming subscriptions from a remote state" below)

### Remote state dependencies (`remote_tfstates`)

To reference outputs from another environment's state, declare the remote state in `remote_tfstates` at the root of the config:

```yaml
remote_tfstates:
  subscriptions:                              # arbitrary key used in ref:
    type: azurerm
    storage_account_name: <tfstate-storage-account>
    container_name: terraform
    key: <org>/subscriptions/<region>/core/terraform.tfstate
    resource_group_name: <tfstate-resource-group>
```

Then reference its outputs anywhere in the same config file:

```yaml
ref:remote_states.subscriptions.azure_subscriptions.app.subscription_id
```

## Config Key to Module Mapping

Each YAML root key maps to a Terraform module in the upstream repo at `modules/azure/<module_name>/`.
The config key is the plural form; the module directory is the singular form.

| Config Key (YAML) | Module Directory | Key Variables |
|---|---|---|
| `azure_resource_groups` | `resource_group` | `resource_group_name`, `location`, `tags` |
| `azure_storage_accounts` | `storage_account` | `resource_group_name`, `account_name`, `sku_name`, `kind`, `location` |
| `azure_storage_account_containers` | `storage_account_container` | `resource_group_name`, `account_name`, `container_name` |
| `azure_key_vaults` | `key_vault` | `resource_group_name`, `vault_name`, `location`, `tenant_id`, `sku_name` |
| `azure_key_vault_keys` | `key_vault_key` | `resource_group_name`, `vault_name`, `key_name` |
| `azure_virtual_networks` | `virtual_network` | `resource_group_name`, `virtual_network_name`, `location`, `address_space`, `subnets` |
| `azure_virtual_network_peerings` | `virtual_network_peering` | depends on module |
| `azure_public_ip_addresses` | `public_ip_address` | `resource_group_name`, `public_ip_address_name`, `location`, `sku_name`, `allocation_method` |
| `azure_managed_clusters` | `managed_cluster` | `resource_group_name`, `cluster_name`, `location` |
| `azure_private_dns_zones` | `private_dns_zone` | `resource_group_name`, `zone_name` |
| `azure_private_endpoints` | `private_endpoint` | `resource_group_name`, `endpoint_name`, `location` |
| `azure_role_assignments` | `role_assignment` | `scope`, `role_definition_id`, `principal_id`, `principal_type` |
| `azure_management_locks` | `management_lock` | `resource_group_name`, `lock_name`, `lock_level` |
| `azure_user_assigned_identities` | `user_assigned_identity` | `resource_group_name`, `identity_name`, `location` |
| `azure_container_registries` | `container_registry` | `resource_group_name`, `registry_name`, `location`, `sku` |
| `azure_postgresql_flexible_servers` | `postgresql_flexible_server` | `resource_group_name`, `server_name`, `location` |
| `azure_redis_enterprise_clusters` | `redis_enterprise_cluster` | `resource_group_name`, `cluster_name`, `location` |
| `azure_redis_enterprise_databases` | `redis_enterprise_database` | depends on module |
| `azure_virtual_wans` | `virtual_wan` | `resource_group_name`, `wan_name`, `location` |
| `azure_virtual_hubs` | `virtual_hub` | `resource_group_name`, `hub_name`, `location` |
| `azure_virtual_hub_connections` | `virtual_hub_connection` | depends on module |
| `azure_firewalls` | `azure_firewall` | `resource_group_name`, `firewall_name`, `location` |
| `azure_firewall_policies` | `firewall_policy` | `resource_group_name`, `policy_name`, `location` |
| `azure_load_balancers` | `load_balancer` | `resource_group_name`, `load_balancer_name`, `location` |
| `azure_network_interfaces` | `network_interface` | depends on module |
| `azure_route_tables` | `route_table` | `resource_group_name`, `route_table_name`, `location` |
| `azure_dns_zones` | `dns_zone` | `resource_group_name`, `zone_name` |
| `azure_dns_record_sets` | `dns_record_set` | depends on module |
| `azure_dns_resolvers` | `dns_resolver` | `resource_group_name`, `dns_resolver_name`, `location` |
| `azure_express_route_ports` | `express_route_port` | depends on module |
| `azure_express_route_circuits` | `express_route_circuit` | depends on module |
| `azure_express_route_circuit_peerings` | `express_route_circuit_peering` | depends on module |
| `azure_virtual_network_gateways` | `virtual_network_gateway` | `resource_group_name`, `gateway_name`, `location` |
| `azure_virtual_network_gateway_connections` | `virtual_network_gateway_connection` | depends on module |
| `azure_vpn_gateways` | `vpn_gateway` | depends on module |
| `azure_network_managers` | `network_manager` | depends on module |
| `azure_ipam_pools` | `ipam_pool` | depends on module |
| `azure_ipam_static_cidrs` | `ipam_static_cidr` | depends on module |
| `azure_resource_provider_registrations` | `resource_provider_registration` | `resource_provider_namespace` |
| `azure_resource_provider_features` | `resource_provider_feature` | depends on module |
| `azure_subscriptions` | `subscription` | `alias_name`, `display_name`, `billing_scope`, `workload` |
| `azure_billing_associated_tenants` | `billing_associated_tenant` | depends on module |
| `azure_communication_services` | `communication_service` | depends on module |
| `azure_email_communication_services` | `email_communication_service` | depends on module |
| `azure_email_communication_service_domains` | `email_communication_service_domain` | depends on module |
| `azure_ciam_directories` | `ciam_directory` | depends on module |
| `azure_arc_connected_clusters` | `arc_connected_cluster` | depends on module |
| `azure_arc_kubernetes_extensions` | `arc_kubernetes_extension` | depends on module |
| `azure_app_service_domains` | `app_service_domain` | depends on module |
| `azure_github_network_settings` | `github_network_settings` | depends on module |
| `azure_container_registry_imports` | `container_registry_import` | depends on module |
| `entraid_groups` | (Entra ID) | `display_name`, `mail_nickname` |
| `entraid_users` | (Entra ID) | `user_principal_name`, `display_name` |
| `entraid_applications` | (Entra ID) | `display_name` |
| `github_runner_groups` | (GitHub) | depends on module |

## Common Patterns

### Every resource should inherit location and tags from its resource group

```yaml
azure_storage_accounts:
  data:
    location: ref:azure_resource_groups.core.location
    tags: ref:azure_resource_groups.core.tags
```

### Creating multiple subscriptions in a single config file

The root-level `subscription_id` is the **deployment target** (an existing subscription the pipeline authenticates against).
To **provision new subscriptions**, use `azure_subscriptions` with one logical key per subscription:

```yaml
azure_subscriptions:
  app:
    alias_name: sub-dev-app
    display_name: "Dev - Application"
    billing_scope: /billingAccounts/<billing-account>/enrollmentAccounts/<enrollment-account>
    workload: DevTest
    management_group_id: /providers/Microsoft.Management/managementGroups/dev
    tags:
      environment: dev
      purpose: application
  data:
    alias_name: sub-dev-data
    display_name: "Dev - Data Platform"
    billing_scope: /billingAccounts/<billing-account>/enrollmentAccounts/<enrollment-account>
    workload: DevTest
    management_group_id: /providers/Microsoft.Management/managementGroups/dev
    tags:
      environment: dev
      purpose: data-platform
```

Each logical key (`app`, `data`) creates a separate subscription. Group all subscriptions for the same environment in one config file.

### Consuming subscriptions from a remote state

Most configurations (networking, compute, etc.) deploy **into** subscriptions that were already created by a separate config.
Declare a `remote_tfstates` entry pointing to the subscription state, then use `ref:remote_states` to pull the subscription ID:

```yaml
# configurations/env-networking/config.yaml

remote_tfstates:
  subscriptions:
    type: azurerm
    storage_account_name: <tfstate-storage-account>
    container_name: terraform
    key: <org>/subscriptions/<region>/core/terraform.tfstate
    resource_group_name: <tfstate-resource-group>

azure_virtual_wans:
  hub:
    subscription_id: ref:remote_states.subscriptions.azure_subscriptions.app.subscription_id
    resource_group_name: ref:azure_resource_groups.networking.name
    wan_name: vwan-hub-001
    location: ref:azure_resource_groups.networking.location
    tags: ref:azure_resource_groups.networking.tags
```

This is the standard pattern: one config file creates subscriptions, and downstream configs consume their `subscription_id` via remote state.

### Properties in config map directly to module variables

The properties under each logical key map 1:1 to the Terraform module's `variables.tf`.
The `subscription_id` is typically inherited from the root-level `subscription_id` unless overridden per resource.

## CI/CD Pipeline

The `.github/workflows/deploy.yml` workflow **auto-discovers** environments by scanning `configurations/env-*/config.yaml`.
Config changes trigger the pipeline automatically. Never modify the pipeline to include Terraform code.

### Adding a New Environment

1. Create `configurations/env-{name}/config.yaml`
2. Set up secrets & variables (suffix = uppercase env name, hyphens → underscores):
   - Secrets: `AZURE_CLIENT_ID_{SUFFIX}`, `AZURE_SUBSCRIPTION_ID_{SUFFIX}`, `AZURE_TENANT_ID`
   - Variables: `AZURE_BACKEND_STORAGE_ACCOUNT_{SUFFIX}`, `AZURE_BACKEND_RESOURCE_GROUP_{SUFFIX}`, `AZURE_BACKEND_CONTAINER_NAME`
3. The `sync-environments.yml` workflow auto-creates the GitHub Environment on push to main.
   Protection rules (required reviewers, wait timers) must be added manually in Settings → Environments.

## Upstream Module Repository

- URL: `https://github.com/LaurentLesle/terraform-rest-galaxy`
- Modules: `modules/azure/<resource_type>/`  
- Each module has: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`
- Module variables define what properties can be set in config YAML

## Upstream Search Constraint

When checking module availability, reading module variables, or performing any lookup against the upstream modules:

1. **ONLY** search in `LaurentLesle/terraform-rest-galaxy` — never in any other repository.
2. Use `fetch_webpage` with the exact raw GitHub URLs below — do NOT use `github_repo` or any other broad search tool:
   - Module listing: `https://github.com/LaurentLesle/terraform-rest-galaxy/tree/main/modules/azure`
   - Module variables: `https://raw.githubusercontent.com/LaurentLesle/terraform-rest-galaxy/main/modules/azure/<module_name>/variables.tf`
   - Module outputs: `https://raw.githubusercontent.com/LaurentLesle/terraform-rest-galaxy/main/modules/azure/<module_name>/outputs.tf`
3. If the upstream repo is cloned locally, you may use `ls` / `cat` on the local clone instead.
4. **Never** search GitHub broadly, search other organisations, or guess module contents from other Terraform providers or registries.
