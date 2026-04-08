# Skill: Configure Backend and Subscription

**Description**: Reconfigure the `terraform_backend` section and `subscription_id` in config YAML files using the GitHub repository variables and secrets. Use when: configure backend, set backend, update backend, set subscription, reconfigure state, setup environment, initialize config, replace placeholders, configure storage account for state, set tfstate backend.

## When to Use

Invoke this skill whenever a user asks to:
- Configure or reconfigure the Terraform backend in config files
- Set the subscription ID for an environment
- Replace placeholder values in the backend or subscription sections
- Initialize a new environment's config with real values

## Prerequisites

The GitHub CLI (`gh`) must be authenticated and the repository must have the following variables and secrets set:

**Secrets** (set via `gh secret set`):
- `AZURE_SUBSCRIPTION_ID_DEV` — Azure subscription ID for dev
- `AZURE_SUBSCRIPTION_ID_PROD` — Azure subscription ID for prod

**Variables** (set via `gh variable set`):
- `AZURE_BACKEND_STORAGE_ACCOUNT_DEV` — Terraform state storage account for dev
- `AZURE_BACKEND_STORAGE_ACCOUNT_PROD` — Terraform state storage account for prod
- `AZURE_BACKEND_RESOURCE_GROUP_DEV` — Resource group containing the state storage account for dev
- `AZURE_BACKEND_RESOURCE_GROUP_PROD` — Resource group containing the state storage account for prod
- `AZURE_BACKEND_CONTAINER_NAME` — Blob container name (shared, typically `terraform`)

## Procedure

### 1. Determine Target Environment(s)

Ask the user which environment to configure if not specified. Valid values: `dev`, `prod`, or both.

### 2. Fetch Variable Values

Read the GitHub repository variables using the `gh` CLI:

```bash
# Variables (readable)
gh variable get AZURE_BACKEND_STORAGE_ACCOUNT_DEV
gh variable get AZURE_BACKEND_STORAGE_ACCOUNT_PROD
gh variable get AZURE_BACKEND_RESOURCE_GROUP_DEV
gh variable get AZURE_BACKEND_RESOURCE_GROUP_PROD
gh variable get AZURE_BACKEND_CONTAINER_NAME
```

> **Important**: Secrets (`AZURE_SUBSCRIPTION_ID_DEV`, `AZURE_SUBSCRIPTION_ID_PROD`) cannot be read back via `gh secret list` — they are write-only. You must **ask the user** for the subscription ID value, or check if it's already set in the config file. Never guess or fabricate a subscription ID.

### 3. Ask for Values That Cannot Be Read

For each target environment, ask the user to provide:
- **Subscription ID** — if the config still has the placeholder `<azure-subscription-id>`
- **State key** — if the config still has `<org>` or `<region>` placeholders in the key. Remind them of the naming convention: `<org>/<env>/<region>/<workload>/terraform.tfstate`

### 4. Update the Config File

For each target environment, edit `configurations/env-{env}/config.yaml`:

#### 4a. Update `terraform_backend`

Replace placeholder values with actual values:

```yaml
terraform_backend:
  type: azurerm
  storage_account_name: {AZURE_BACKEND_STORAGE_ACCOUNT_{ENV}}
  container_name: {AZURE_BACKEND_CONTAINER_NAME}
  key: <org>/<env>/<region>/<workload>/terraform.tfstate  # ask user if still placeholder
  resource_group_name: {AZURE_BACKEND_RESOURCE_GROUP_{ENV}}
```

#### 4b. Update root-level `subscription_id`

```yaml
subscription_id: "{value provided by user}"
```

#### 4c. Update per-resource `subscription_id`

Scan the config file for any resource entries that have `subscription_id: "<azure-subscription-id>"` and replace them with the actual subscription ID.

### 5. Verify

After editing, display the updated `terraform_backend` and `subscription_id` sections so the user can confirm correctness.

Remind the user to also check:
- The `key` follows the naming convention: `<org>/<env>/<region>/<workload>/terraform.tfstate`
- The storage account and resource group actually exist in Azure (this skill does NOT create them)

## Example Interaction

**User**: "Configure the backend for dev and prod"

**Agent**:
1. Runs `gh variable get AZURE_BACKEND_STORAGE_ACCOUNT_DEV` → `stterraformdev001`
2. Runs `gh variable get AZURE_BACKEND_RESOURCE_GROUP_DEV` → `rg-terraform-state-dev`
3. Runs `gh variable get AZURE_BACKEND_CONTAINER_NAME` → `terraform`
4. Asks user: "What is the Azure subscription ID for dev?" → user provides `aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee`
5. Asks user: "What org name and region should I use for the state key?" → user says `acme`, `westeurope`
6. Updates `configurations/env-dev/config.yaml`:

```yaml
terraform_backend:
  type: azurerm
  storage_account_name: stterraformdev001
  container_name: terraform
  key: acme/dev/westeurope/core-infra/terraform.tfstate
  resource_group_name: rg-terraform-state-dev

subscription_id: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
```

7. Repeats for prod.

## Rules

1. **NEVER fabricate subscription IDs or storage account names** — always read from `gh variable get` or ask the user
2. **NEVER read secrets** — `gh secret get` does not exist; secrets are write-only
3. **Preserve all other content** in the config file — only update backend, subscription_id, and per-resource subscription_id fields
4. **Always show the user what changed** before confirming completion
