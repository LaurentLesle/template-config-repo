# Skill: Check Upstream Modules

**Description**: Verify whether Terraform modules exist in the upstream `LaurentLesle/terraform-rest-galaxy` repository and whether they support the requested properties. Use when: generating config, checking module availability, gap analysis, verifying properties, module exists, variable check, schema check.

## Critical Constraint

> **ONLY search in `LaurentLesle/terraform-rest-galaxy`.** Do NOT use `github_repo`, code-search, or any tool that searches across multiple repositories. Use ONLY `fetch_webpage` with the exact URLs specified below, or `ls`/`cat` on a local clone of the upstream repo. Never infer module contents from other Terraform providers, the Terraform registry, or any other source.

## When to Use

Invoke this skill whenever you need to:
- Verify a module exists before generating config
- Check if a specific property/variable is supported by a module
- Produce a gap analysis table for the user
- Determine if an upstream issue needs to be filed

## Procedure

### 1. List Available Modules

Fetch the upstream module directory listing to see all available modules:

```
URL: https://github.com/LaurentLesle/terraform-rest-galaxy/tree/main/modules/azure
```

Use `fetch_webpage` with query "modules azure" to get the directory listing.
Parse the page for directory names — each directory name is a module.

Alternatively, if the upstream repo is cloned locally, use the terminal:
```bash
ls modules/azure/
```

### 2. Check Module Existence

For a requested resource type, derive the module name:
1. Take the YAML config key (e.g., `azure_storage_accounts`)
2. Strip the `azure_` prefix → `storage_accounts`
3. Convert to singular → `storage_account`
4. Check if `modules/azure/storage_account/` exists

Common singular transformations:
| Config Key | Module Directory |
|---|---|
| `azure_resource_groups` | `resource_group` |
| `azure_storage_accounts` | `storage_account` |
| `azure_key_vaults` | `key_vault` |
| `azure_virtual_networks` | `virtual_network` |
| `azure_managed_clusters` | `managed_cluster` |
| `azure_private_dns_zones` | `private_dns_zone` |
| `azure_private_endpoints` | `private_endpoint` |
| `azure_role_assignments` | `role_assignment` |
| `azure_management_locks` | `management_lock` |
| `azure_container_registries` | `container_registry` |
| `azure_firewalls` | `azure_firewall` |
| `azure_firewall_policies` | `firewall_policy` |
| `azure_redis_enterprise_clusters` | `redis_enterprise_cluster` |
| `azure_redis_enterprise_databases` | `redis_enterprise_database` |
| `azure_postgresql_flexible_servers` | `postgresql_flexible_server` |
| `azure_dns_zones` | `dns_zone` |
| `azure_dns_record_sets` | `dns_record_set` |
| `azure_dns_resolvers` | `dns_resolver` |
| `azure_load_balancers` | `load_balancer` |
| `azure_virtual_wans` | `virtual_wan` |
| `azure_virtual_hubs` | `virtual_hub` |
| `azure_vpn_gateways` | `vpn_gateway` |
| `azure_public_ip_addresses` | `public_ip_address` |
| `azure_route_tables` | `route_table` |
| `azure_virtual_network_gateways` | `virtual_network_gateway` |
| `azure_network_interfaces` | `network_interface` |
| `azure_user_assigned_identities` | `user_assigned_identity` |
| `azure_communication_services` | `communication_service` |
| `azure_email_communication_services` | `email_communication_service` |
| `azure_storage_account_containers` | `storage_account_container` |
| `azure_key_vault_keys` | `key_vault_key` |

### 3. Fetch Module Variables

For each existing module, fetch its `variables.tf` to get the supported properties:

```
URL: https://raw.githubusercontent.com/LaurentLesle/terraform-rest-galaxy/main/modules/azure/<module_name>/variables.tf
```

Use `fetch_webpage` with query "variable" to get the variables.

Parse each `variable "<name>"` block to extract:
- **Variable name** — this is the property name to use in config YAML
- **Type** — `string`, `bool`, `number`, `list(string)`, `map(string)`, `object(...)`, etc.
- **Default** — if `null` or absent, the variable is required; if set, it's optional
- **Description** — human-readable explanation
- **Validation** — allowed values (from `condition` blocks)

### 4. Compare Requested Properties

For each property the user wants to set:
1. Check if a `variable` with that exact name exists in `variables.tf`
2. If it exists, verify the type matches the user's intended value
3. If it doesn't exist, flag as **missing** (⚠️)

### 5. Check Module Outputs

Optionally, fetch `outputs.tf` to understand what attributes are available for `ref:` usage:

```
URL: https://raw.githubusercontent.com/LaurentLesle/terraform-rest-galaxy/main/modules/azure/<module_name>/outputs.tf
```

Key outputs (commonly used in `ref:` expressions):
- `id` — the ARM resource ID
- `name` — the resource name
- Other module-specific outputs

### 6. Return Results

Return a structured result for each module checked:

```
Module: storage_account
Status: ✅ exists
Variables (supported):
  - subscription_id (string, required)
  - resource_group_name (string, required)
  - account_name (string, optional — defaults to null)
  - sku_name (string, required — Standard_LRS|Standard_GRS|...)
  - kind (string, required — StorageV2|BlobStorage|...)
  - location (string, required)
  - tags (map(string), optional)
  - https_traffic_only_enabled (bool, optional — default true)
  - identity_type (string, optional)
Missing requested properties: (none)
```

Or for a missing module:

```
Module: app_service
Status: ❌ does not exist
Recommendation: Open an issue at https://github.com/LaurentLesle/terraform-rest-galaxy/issues
  requesting a new module for Microsoft.Web/sites (Azure App Service)
```

## Caching

If you've already fetched a module's `variables.tf` during this session, don't fetch it again.
The upstream module structure doesn't change during a single user session.
