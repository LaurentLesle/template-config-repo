# Skill: Open Upstream Issue

**Description**: Open a GitHub issue on the upstream module repository (`LaurentLesle/terraform-rest-galaxy`) when the gap analysis identifies a missing module, missing property, or API version update. Use when: module missing, property missing, new attribute needed, version update, upstream issue, file issue, request module, request property, gap analysis follow-up.

## Prerequisites

The user must have the GitHub CLI (`gh`) installed and authenticated with access to create issues on `LaurentLesle/terraform-rest-galaxy`:

```bash
gh auth status  # verify authentication
```

If not authenticated, guide the user:
```bash
gh auth login
```

## When to Use

Invoke this skill after the `check-upstream-modules` skill identifies:
- ❌ **Missing module** — resource type has no module in the upstream repo
- ⚠️ **Missing property** — module exists but lacks a variable for a requested property
- ⚠️ **API version update** — module exists but uses an outdated API version

## Issue Types

### Type 1: New Module Request

When a resource type has no corresponding module (❌ status).

**Label**: `new-module`

**Template**:
```
Title: [New Module] <resource_type> (Microsoft.<Provider>/<ResourceType>)

## Resource Type
- Azure resource provider: `Microsoft.<Provider>/<ResourceType>`
- Proposed config key: `azure_<plural_name>`
- Proposed module directory: `modules/azure/<singular_name>/`

## Use Case
<description of why this module is needed, from the user's request>

## Requested Properties
The following properties are needed based on the consumer configuration:

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| <name> | <type> | yes/no | <description> |

## Azure REST API Reference
- API version: <latest stable version>
- Docs: https://learn.microsoft.com/rest/api/<path>

## Consumer Config Example
```yaml
azure_<plural_name>:
  <key>:
    <property>: <value>
```
```

**Command**:
```bash
gh issue create \
  --repo LaurentLesle/terraform-rest-galaxy \
  --title "[New Module] <resource_type> (Microsoft.<Provider>/<ResourceType>)" \
  --label "new-module" \
  --body "<body from template above>"
```

### Type 2: New Property / Attribute Request

When a module exists but is missing a variable for a requested property (⚠️ status).

**Label**: `new-property`

**Template**:
```
Title: [New Property] <module_name>: add `<property_name>` variable

## Module
- Module directory: `modules/azure/<module_name>/`
- Config key: `azure_<plural_name>`

## Requested Property
- Variable name: `<property_name>`
- Type: `<terraform_type>` (string, bool, number, list, map, object)
- Required: yes / no (default: `<default_value>`)
- Description: <what the property controls>

## Azure REST API Mapping
- API path: `properties.<jsonPath>`
- API version: <current module API version>
- Value type: <JSON type>
- Docs: https://learn.microsoft.com/rest/api/<path>

## Use Case
<description of why this property is needed>

## Consumer Config Example
```yaml
azure_<plural_name>:
  <key>:
    <property_name>: <example_value>
```
```

**Command**:
```bash
gh issue create \
  --repo LaurentLesle/terraform-rest-galaxy \
  --title "[New Property] <module_name>: add \`<property_name>\` variable" \
  --label "new-property" \
  --body "<body from template above>"
```

### Type 3: API Version Update

When a module uses an outdated API version and the user needs features from a newer version.

**Label**: `api-version`

**Template**:
```
Title: [API Version] <module_name>: update to <new_api_version>

## Module
- Module directory: `modules/azure/<module_name>/`
- Current API version: `<current_version>` (from module's main.tf)
- Requested API version: `<new_version>`

## Reason for Update
<why the newer API version is needed — new properties, deprecations, etc.>

## New Properties Available in <new_version>
| Property | API Path | Description |
|----------|----------|-------------|
| <name> | `properties.<path>` | <description> |

## Breaking Changes
<any known breaking changes between versions, or "None expected">

## Azure REST API Reference
- Changelog: https://learn.microsoft.com/rest/api/<path>?api-version=<new_version>
```

**Command**:
```bash
gh issue create \
  --repo LaurentLesle/terraform-rest-galaxy \
  --title "[API Version] <module_name>: update to <new_api_version>" \
  --label "api-version" \
  --body "<body from template above>"
```

## Procedure

### Step 1: Gather Context

From the gap analysis result, extract:
- The resource type and module name
- The specific missing properties or module
- The user's use case (from their original request)

### Step 2: Determine Issue Type

- No module at all → **Type 1: New Module**
- Module exists, property missing → **Type 2: New Property**
- Module exists, API version too old → **Type 3: API Version**

### Step 3: Look Up Azure REST API Details

To fill in the API reference section, fetch the Azure REST API spec:
- Use `fetch_webpage` to look up the resource type at `https://learn.microsoft.com/rest/api/` 
- Identify the correct API version and JSON property path
- This helps the upstream maintainer implement the change correctly

### Step 4: Confirm with User

Before creating the issue, show the user the full issue body and ask for confirmation:

```
I'm about to create this issue on LaurentLesle/terraform-rest-galaxy:

Title: [New Property] storage_account: add `network_acls` variable
Labels: new-property
Body: <preview>

Create this issue? (yes/no)
```

**NEVER create an issue without explicit user confirmation.**

### Step 5: Create the Issue

Run the `gh issue create` command in the terminal. Capture and display the issue URL.

```bash
gh issue create \
  --repo LaurentLesle/terraform-rest-galaxy \
  --title "..." \
  --label "..." \
  --body "..."
```

### Step 6: Record in Config

Add a YAML comment above the affected resource block noting the dependency:

```yaml
# ⚠️ Pending: network_acls property — see https://github.com/LaurentLesle/terraform-rest-galaxy/issues/123
azure_key_vaults:
  main:
    vault_name: kv-myorg-prod-main
    # network_acls: ...  # Uncomment when upstream issue is resolved
```

## Labels

Ensure these labels exist on the upstream repo. If they don't, the `gh` command will still work but without labels. The upstream maintainer can create them:

| Label | Color | Description |
|-------|-------|-------------|
| `new-module` | `#0E8A16` | Request for a new resource module |
| `new-property` | `#1D76DB` | Request to add a property to an existing module |
| `api-version` | `#D93F0B` | Request to update the API version of a module |
| `from-config-repo` | `#BFDADC` | Issue originated from a consumer config repository |

## Error Handling

- **`gh` not installed**: Tell the user to install it: `brew install gh` (macOS) or see https://cli.github.com
- **Not authenticated**: Run `gh auth login`
- **No repo access**: The user needs at least read access to create issues on public repos, or write access for private repos
- **Label doesn't exist**: Create the issue without the label and mention the suggested label in the body
