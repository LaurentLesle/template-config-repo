# Skill: Check Upgrade

**Description**: Analyze the impact of upgrading the upstream `LaurentLesle/galaxy/rest` Terraform module to a new version. Detects breaking changes, renamed attributes, new resources, and generates a migration plan. Use when: upgrade module, bump version, new release, breaking changes, migration, version update, dependabot PR, check compatibility, diff versions.

> **Automated equivalent**: `.github/workflows/check-upgrade.yml` runs this analysis weekly and opens a PR with migration report automatically. This skill is for interactive, on-demand use via Copilot.

## When to Use

Invoke this skill whenever:
- Dependabot opens a PR bumping the module version in `main.tf`
- A user asks to upgrade the upstream module
- A user asks what changed between module versions
- A `terraform plan` fails after a version bump

## Procedure

### 1. Identify Current and Target Versions

Read the current version from `main.tf`:

```bash
grep 'version' main.tf
```

Determine the target version:
- If from a Dependabot PR, read the new version from the PR diff
- If the user specifies a version, use that
- Otherwise, fetch the latest from the registry:

```bash
# Get latest release tag from the upstream repo
gh release list --repo LaurentLesle/terraform-rest-galaxy --limit 1
```

### 2. Fetch Release Notes

Get the release notes for all versions between current and target:

```bash
gh release view <tag> --repo LaurentLesle/terraform-rest-galaxy
```

If multiple versions are being skipped, fetch each one:

```bash
gh release list --repo LaurentLesle/terraform-rest-galaxy --limit 20
```

Then view each relevant release. Collect:
- Breaking changes
- New modules/resources
- Removed or renamed variables
- API version updates

### 3. Diff Module Variables

For each resource type used in the config files, compare the old and new `variables.tf`.

#### 3a. Identify resource types in use

Parse the config YAML files to find all top-level keys that map to module resource types:

```bash
# Extract resource type keys from config files
grep -E '^[a-z_]+:' configurations/env-*/config.yaml | grep -v '#' | grep -v 'terraform_backend' | grep -v 'subscription_id' | grep -v 'default_location'
```

#### 3b. Fetch old and new variables for each module

For each resource type in use (e.g., `azure_storage_accounts` → module `storage_account`):

```
Old: https://raw.githubusercontent.com/LaurentLesle/terraform-rest-galaxy/<old-tag>/modules/azure/<module>/variables.tf
New: https://raw.githubusercontent.com/LaurentLesle/terraform-rest-galaxy/<new-tag>/modules/azure/<module>/variables.tf
```

Use `fetch_webpage` to retrieve both and compare.

#### 3c. Classify changes

For each variable, determine:
- **Added** — new variable in the new version (no action needed, new capability)
- **Removed** — variable existed in old, gone in new (⚠️ breaking if used in config)
- **Renamed** — old name removed + new similar name added (⚠️ migration needed)
- **Type changed** — same name but different type signature (⚠️ may need config update)
- **Default changed** — same name, same type, different default (ℹ️ review behavior)

### 4. Scan Config for Impact

For each removed or renamed variable, scan the config files to check if it's actually used:

```bash
grep -rn '<attribute_name>' configurations/
```

Only flag changes that affect attributes actually present in the user's configs.

### 5. Present Migration Table

Show a summary table:

```
| Module           | Attribute              | Change       | Used in Config | Action Required                    |
|------------------|------------------------|--------------|----------------|------------------------------------|
| storage_account  | https_only             | renamed      | env-dev, env-prod | Rename to https_traffic_only_enabled |
| storage_account  | encryption_key_source  | new          | —              | Now available — no action needed   |
| key_vault        | network_acls           | type changed | env-prod       | Update object structure (see below) |
| managed_cluster  | —                      | new module   | —              | AKS is now available               |
```

Group by severity:
1. **🔴 Breaking** — attribute removed/renamed and used in config → must fix before upgrading
2. **🟡 Review** — type or default changed for used attribute → verify config still valid
3. **🟢 New** — new attributes or modules → no action, new capabilities available

### 6. Generate Migration Steps

For each breaking change, provide the exact edit:

```
### Migration: storage_account.https_only → https_traffic_only_enabled

Files affected:
- configurations/env-dev/config.yaml (line 42)
- configurations/env-prod/config.yaml (line 38)

Before:
    https_only: true

After:
    https_traffic_only_enabled: true
```

### 7. Apply Migrations (with user consent)

Ask the user:

> "I found N breaking changes that need migration. Would you like me to apply the safe renames automatically?"

If the user agrees:
1. Apply each rename/restructure in the config files
2. Update the version in `main.tf`
3. Show the user the final diff

If the user declines:
1. Still update version in `main.tf` if requested
2. List remaining manual steps

### 8. Verify

After applying migrations:

```bash
# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('configurations/env-dev/config.yaml'))"
python3 -c "import yaml; yaml.safe_load(open('configurations/env-prod/config.yaml'))"
```

Suggest the user run `terraform plan` to verify:

```bash
terraform init -upgrade
terraform plan -var="config_file=configurations/env-dev/config.yaml"
```

## Rules

1. **NEVER upgrade without showing the migration table first** — the user must see the impact
2. **NEVER auto-apply migrations without user consent** — breaking changes require explicit approval
3. **ALWAYS check actual config usage** — don't flag changes for attributes not used in config
4. **Fetch real data** — always compare actual `variables.tf` files, don't guess from release notes alone
5. **Handle multi-version jumps** — if skipping v1.1 → v1.3, check all intermediate changelogs
