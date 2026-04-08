# Getting Started with GitHub Copilot Agent Mode

This guide walks you through creating Azure infrastructure configurations using the built-in **`infra` Copilot agent mode** — no Terraform knowledge required.

## Prerequisites

| Requirement | How to verify |
|---|---|
| **VS Code** with GitHub Copilot extension | Extensions panel → search "GitHub Copilot" |
| **GitHub CLI** (`gh`) authenticated | `gh auth status` |
| This repo cloned and opened in VS Code | `code /path/to/template-config-repo` |

> **Why `gh` CLI?** The agent can file upstream issues when a module or property is missing. If you don't need that, the CLI is optional.

## 1. Select the `infra` Agent Mode

1. Open **Copilot Chat** in VS Code (`Ctrl+Shift+I` / `Cmd+Shift+I`)
2. At the top of the chat panel, click the **mode selector** (it may say "Ask" or "Edit")
3. Choose **`infra`** from the list

The `infra` agent is defined in [`.github/agents/infra.md`](.github/agents/infra.md) and is purpose-built for this repository. It understands the YAML config schema, cross-resource references, naming conventions, and the full catalog of upstream Terraform modules.

## 2. Describe What You Need (in Plain English)

Just tell the agent what infrastructure you want. Here are some example prompts:

### Simple resource

> I need a resource group and a storage account in westeurope for dev

### Multi-resource setup

> Create a dev environment with a resource group, a Key Vault, and a virtual network with two subnets (app and data) in northeurope

### Specific requirements

> Add a PostgreSQL Flexible Server in the dev config with zone redundancy and 4 vCores, behind a private endpoint

### Production variant

> Copy the dev storage account config to prod but change the SKU to Standard_GRS

### Configure the backend

> Configure the backend and subscription for dev and prod

## 3. Understand the Agent Workflow

When you submit a request, the agent follows a structured process:

### Step 1 — Parse your request
The agent extracts resource types, properties, relationships, and the target environment from your prompt.

### Step 2 — Check upstream modules
For each resource type, the agent checks the upstream module repository ([terraform-rest-galaxy](https://github.com/LaurentLesle/terraform-rest-galaxy)) to verify:
- The module exists
- The requested properties are supported as Terraform variables

### Step 3 — Show a gap analysis
Before generating any config, the agent presents a summary table:

```
| Resource        | Config Key               | Module          | Status | Notes                    |
|-----------------|--------------------------|-----------------|--------|--------------------------|
| Resource Group  | azure_resource_groups    | resource_group  | ✅     | All properties supported |
| Storage Account | azure_storage_accounts   | storage_account | ✅     | Ready                    |
| App Service     | azure_app_services       | (none)          | ❌     | No module exists         |
```

- **✅ Ready** — module exists with all requested properties
- **⚠️ Partial** — module exists but some properties are missing
- **❌ Missing** — no upstream module for this resource type

### Step 4 — File upstream issues (if gaps exist)
If any resources are ⚠️ or ❌, the agent offers to open GitHub issues on the upstream repo to request the missing modules or properties. **It always asks for your confirmation before creating an issue.**

### Step 5 — Generate YAML config
The agent writes valid YAML config into the appropriate `configurations/env-{env}/config.yaml` file, following all conventions:
- Uses `ref:` for cross-resource references (location, tags, resource group name)
- Follows naming conventions (`rg-{org}-{env}-{workload}`, `kv-{org}-{env}-{purpose}`, etc.)
- Appends to existing config rather than overwriting

## 4. Review and Customize the Output

After the agent generates the config, review it in the editor. Common things to check:

- **Placeholder values** — Replace any `<org>`, `<subscription-id>`, or similar placeholders with your real values
- **Naming** — Adjust resource names to match your organization's conventions
- **SKU / sizing** — Confirm the SKU, tier, or sizing matches your requirements
- **Tags** — Add or modify tags as needed

### Example generated config

```yaml
azure_resource_groups:
  core:
    subscription_id: "<azure-subscription-id>"
    name: rg-acme-dev-core
    location: westeurope
    tags:
      environment: dev
      managed_by: terraform

azure_storage_accounts:
  data:
    subscription_id: "<azure-subscription-id>"
    resource_group_name: ref:azure_resource_groups.core.name
    account_name: acmedevdata001
    sku_name: Standard_LRS
    kind: StorageV2
    location: ref:azure_resource_groups.core.location
    https_only: true
    tags: ref:azure_resource_groups.core.tags
```

## 5. Deploy Your Changes

Once your config looks good:

```bash
# Create a feature branch
git checkout -b feature/add-storage-account

# Stage and commit
git add configurations/
git commit -m "Add storage account for dev environment"

# Push and open a PR
git push origin feature/add-storage-account
gh pr create --title "Add storage account for dev" --body "Generated via Copilot infra agent"
```

The CI/CD pipeline will automatically:
1. **On PR** — run `terraform plan` and post the result as a PR comment
2. **On merge to `main`** — run `terraform apply` (with approval gate for prod)

## Tips and Tricks

### Ask follow-up questions
The agent maintains context within the conversation. You can ask:
> "Now add a private endpoint for that storage account"
> "Change the location to northeurope"
> "Also create the same setup for prod"

### Ask about supported properties
> "What properties does the storage account module support?"

The agent will fetch the upstream `variables.tf` and list all available properties with their types and defaults.

### Ask for help with references
> "How do I reference the Key Vault ID from the storage account config?"

### Target a specific environment
If you don't specify, the agent will ask. Be explicit to skip the prompt:
> "Add a Redis cache to the **prod** config"

### Iterate on existing config
You can ask the agent to modify existing entries:
> "Change the storage account SKU from Standard_LRS to Standard_GRS in dev"

## Troubleshooting

| Problem | Solution |
|---|---|
| Agent mode `infra` doesn't appear | Make sure you have the repo open as a workspace in VS Code and GitHub Copilot Chat is installed |
| "Module not found" for a resource | The upstream repo may not support it yet — let the agent file an issue |
| `gh` command fails | Run `gh auth login` to authenticate the GitHub CLI |
| Config has `<placeholder>` values | Replace them with your actual Azure subscription ID, org name, etc. |
| Plan fails after merge | Check the Terraform plan output in the PR comment — common causes are invalid names or missing permissions |

## Further Reading

- [Repository README](../README.md) — full setup and deployment instructions
- [Copilot instructions](../.github/copilot-instructions.md) — YAML schema reference and module mapping table
- [Infra agent definition](../.github/agents/infra.md) — the agent's full behavior specification
- [Upstream module repo](https://github.com/LaurentLesle/terraform-rest-galaxy) — Terraform modules and API docs
