# Infrastructure Configuration Repository

This repository holds **YAML configuration files** that define your Azure infrastructure. It calls reusable Terraform workflows from the [terraform-rest-galaxy](https://github.com/LaurentLesle/terraform-rest-galaxy) module repository — you never need to write Terraform code.

## Agent-Assisted Configuration

This repo ships with a custom **Copilot agent mode** (`infra`) that:

1. Accepts natural language infrastructure requests
2. Checks upstream modules for availability and property support
3. Generates YAML config with proper `ref:` cross-references
4. Opens GitHub issues on the upstream repo when modules or properties are missing

**To use it**: Open this repo in VS Code → select the `infra` agent mode → describe what you need.

Requires: `gh` CLI authenticated (`gh auth login`) for filing upstream issues.

**→ [Getting Started with Copilot Agent Mode](docs/getting-started-copilot.md)** — step-by-step guide with examples.

## Getting Started

### 1. Create your repository from this template

Click **"Use this template"** → **"Create a new repository"** on GitHub (private recommended).

### 2. Configure Azure credentials

Set up OIDC federation between GitHub Actions and Azure:

```bash
# Create an App Registration and federated credential for each environment
# See: https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust

# Then set repository secrets:
gh secret set AZURE_CLIENT_ID_DEV   --body "<client-id-for-dev>"
gh secret set AZURE_CLIENT_ID_PROD  --body "<client-id-for-prod>"
gh secret set AZURE_TENANT_ID       --body "<tenant-id>"
gh secret set AZURE_SUBSCRIPTION_ID_DEV  --body "<subscription-id-dev>"
gh secret set AZURE_SUBSCRIPTION_ID_PROD --body "<subscription-id-prod>"

# Set repository variables for Terraform backend storage:
gh variable set AZURE_BACKEND_STORAGE_ACCOUNT_DEV  --body "<tfstate-storage-account-dev>"
gh variable set AZURE_BACKEND_STORAGE_ACCOUNT_PROD --body "<tfstate-storage-account-prod>"
gh variable set AZURE_BACKEND_RESOURCE_GROUP_DEV   --body "<tfstate-resource-group-dev>"
gh variable set AZURE_BACKEND_RESOURCE_GROUP_PROD  --body "<tfstate-resource-group-prod>"
gh variable set AZURE_BACKEND_CONTAINER_NAME       --body "terraform"
```

### 3. Configure GitHub Environments

1. Go to **Settings → Environments**
2. Create `dev` and `prod` environments
3. For `prod`, add **required reviewers** (approval gate before apply)

### 4. Edit configuration files

Update the example configs under `configurations/` with your values:

- `configurations/env-dev/config.yaml` — Development environment
- `configurations/env-prod/config.yaml` — Production environment

### 5. Deploy

```bash
git checkout -b feature/initial-setup
# Edit configs...
git add . && git commit -m "Initial infrastructure configuration"
git push origin feature/initial-setup
# Open a PR → plan runs automatically
# Merge to main → apply runs with environment approval
```

## Repository Structure

```
├── .github/
│   ├── workflows/
│   │   ├── deploy.yml          # Calls reusable workflow from module repo
│   │   ├── changelog.yml       # Updates CHANGELOG.md on release
│   │   ├── check-upgrade.yml   # Checks for new module versions + migration report
│   │   └── sync-template.yml   # Syncs shared files from template repo
│   ├── skills/
│   │   ├── check-upstream-modules/  # Verify module availability
│   │   ├── check-upgrade/           # Analyze version upgrade impact
│   │   ├── configure-backend/       # Set backend from GitHub variables
│   │   └── open-upstream-issue/     # File issues on module repo
│   ├── agents/
│   │   └── infra.md            # Copilot agent mode definition
│   ├── ISSUE_TEMPLATE/
│   │   └── infra-change.md     # Template for infrastructure change requests
│   ├── release.yml             # GitHub auto-generated release notes config
│   ├── dependabot.yml          # Auto-updates module version + actions
│   ├── pull_request_template.md
│   └── CODEOWNERS
├── configurations/
│   ├── env-dev/
│   │   └── config.yaml         # Dev environment config
│   └── env-prod/
│       └── config.yaml         # Prod environment config
├── CHANGELOG.md                # Auto-updated changelog
├── main.tf                     # Root module — calls upstream module
├── variables.tf                # Input variables (config_file, tokens, etc.)
├── outputs.tf                  # Proxied outputs from upstream module
└── README.md
```

## Configuration Schema

Each `config.yaml` must include a `terraform_backend` section and at least one resource:

```yaml
terraform_backend:
  type: azurerm
  storage_account_name: <state-storage-account>
  container_name: terraform
  key: <org>/<env>/<region>/<workload>/terraform.tfstate
  resource_group_name: <state-rg>

subscription_id: "<azure-subscription-id>"

azure_resource_groups:
  mygroup:
    subscription_id: "<azure-subscription-id>"
    name: rg-myorg-dev-core
    location: westeurope
    tags:
      environment: dev
      managed_by: terraform
```

### State Key Naming Convention

Format: `<org>/<env>/<region>/<workload>/terraform.tfstate`

| Segment      | Example         | Description                        |
| ------------ | --------------- | ---------------------------------- |
| `<org>`      | `acme`          | Organization name (lowercase)      |
| `<env>`      | `dev`           | `dev`, `staging`, or `prod`        |
| `<region>`   | `westeurope`    | Azure region                       |
| `<workload>` | `core-infra`    | Workload name                      |

### Cross-Resource References

Use `ref:` to reference attributes from other resources in the same config:

```yaml
azure_storage_accounts:
  data:
    resource_group_name: ref:azure_resource_groups.core.name
    location: ref:azure_resource_groups.core.location
    tags: ref:azure_resource_groups.core.tags
```

### Supported Resources

All modules available in the module repository:

- `azure_resource_groups`
- `azure_storage_accounts`
- `azure_key_vaults`
- `azure_managed_clusters`
- `azure_postgresql_flexible_servers`
- `azure_data_lake_store_gen2_file_systems`
- And more — see [module repo docs](https://github.com/LaurentLesle/terraform-rest-galaxy)

## Workflow

| Event             | Action | Environment Approval |
| ----------------- | ------ | -------------------- |
| Pull Request      | `plan` | No                   |
| Merge to `main`   | `apply`| Yes (prod)           |

### Automated Maintenance

Two scheduled workflows keep the repo up to date:

| Workflow | Schedule | What it does |
| --- | --- | --- |
| **Check Module Upgrade** (`check-upgrade.yml`) | Monday 09:00 UTC | Detects new versions of the upstream module, diffs `variables.tf` for every module in use, and opens a PR with the version bump + a migration report (breaking changes, renames, new capabilities) |
| **Sync Template** (`sync-template.yml`) | Monday 08:00 UTC | Pulls updated skills, agents, copilot instructions, Terraform root files, and docs from the upstream template repo. Never touches `configurations/` |

Both workflows open PRs for review — nothing is merged automatically. You can also trigger either workflow manually from the Actions tab.

Dependabot keeps GitHub Actions references up to date separately.

### Version Pinning

The workflow pins the module repo version via the `MODULE_REPO_TAG` env var in `.github/workflows/deploy.yml`. Always pin to a release tag:

```yaml
env:
  MODULE_REPO_TAG: v1.0.1  # Pin to specific release
```

To upgrade: update the tag, test in `dev`, then promote to `prod`.

## Local Testing

This repo includes a root Terraform module (`main.tf`, `variables.tf`, `outputs.tf`) that wraps the upstream [terraform-rest-galaxy](https://github.com/LaurentLesle/terraform-rest-galaxy) module. You can run `terraform plan` directly from this repo.

### Using the root module

```bash
# Authenticate
export TF_VAR_azure_access_token=$(az account get-access-token \
  --resource https://management.azure.com --query accessToken -o tsv)
export TF_VAR_subscription_id=$(az account show --query id -o tsv)

# Initialize with backend config (or use -backend=false for plan-only)
terraform init \
  -backend-config="storage_account_name=<tfstate-storage-account>" \
  -backend-config="resource_group_name=<tfstate-resource-group>" \
  -backend-config="container_name=terraform" \
  -backend-config="key=<org>/dev/westeurope/core-infra/terraform.tfstate"

# Plan against a config file
terraform plan -var="config_file=configurations/env-dev/config.yaml"
```

For a quick plan without state (no backend required):

```bash
terraform init -backend=false
terraform plan -var="config_file=configurations/env-dev/config.yaml"
```

### Using the upstream repo directly

Alternatively, clone the module repo and use its `tf.sh` wrapper:

```bash
git clone https://github.com/LaurentLesle/terraform-rest-galaxy.git
cd terraform-rest-galaxy

export TF_VAR_azure_access_token=$(az account get-access-token \
  --resource https://management.azure.com --query accessToken -o tsv)
export TF_VAR_subscription_id=$(az account show --query id -o tsv)

TF_CI_MODE=true ./tf.sh plan /path/to/your-config-repo/configurations/env-dev/config.yaml
```

## References

- [Module Repository](https://github.com/LaurentLesle/terraform-rest-galaxy) — Terraform modules and reusable workflows
- [Consumer Documentation](https://github.com/LaurentLesle/terraform-rest-galaxy/blob/main/.github/CONSUMER_DOCUMENTATION.md) — Full config schema and deployment guide
- [Azure REST API Docs](https://learn.microsoft.com/rest/api/azure/)
