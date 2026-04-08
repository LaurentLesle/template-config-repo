# ── Input Variables ───────────────────────────────────────────────────────────

# ── Config file ──────────────────────────────────────────────────────────────

variable "config_file" {
  type        = string
  description = "Path to the YAML configuration file (e.g. configurations/env-dev/config.yaml)."
}

# ── Azure authentication ─────────────────────────────────────────────────────

variable "azure_access_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "Pre-fetched Azure access token for the management.azure.com audience."
}

variable "azure_refresh_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "Azure CLI refresh token. Auto-renews during long operations. Injected by tf.sh."
}

variable "azure_token_url" {
  type        = string
  default     = null
  description = "OAuth2 token endpoint URL. Injected by tf.sh."
}

variable "arm_tenant_tokens" {
  type        = map(string)
  sensitive   = true
  default     = {}
  description = "Map of tenant_id to ARM bearer token for cross-tenant access."
}

# ── Graph authentication ─────────────────────────────────────────────────────

variable "graph_access_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "Pre-fetched access token for the graph.microsoft.com audience."
}

variable "graph_refresh_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "Azure CLI refresh token for the graph.microsoft.com audience."
}

variable "graph_token_url" {
  type        = string
  default     = null
  description = "OAuth2 token endpoint URL for Graph. Injected by tf.sh."
}

# ── GitHub authentication ────────────────────────────────────────────────────

variable "github_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "GitHub personal access token or GitHub App token."
}

# ── Azure defaults ───────────────────────────────────────────────────────────

variable "subscription_id" {
  type        = string
  default     = null
  description = "Default Azure subscription ID. Used when a resource entry omits subscription_id."
}

variable "tenant_id" {
  type        = string
  default     = null
  description = "Default Azure AD tenant ID."
}

variable "default_location" {
  type        = string
  default     = null
  description = "Default Azure region for resources that omit an explicit location."
}

variable "caller_object_id" {
  type        = string
  default     = null
  description = "Object ID of the current caller. Available in YAML as ref:caller.object_id."
}

# ── Behavior flags ───────────────────────────────────────────────────────────

variable "fail_on_warning" {
  type        = bool
  default     = false
  description = "When true, validate_externals raises an error if any API validation warning occurs."
}

variable "check_existance" {
  type        = bool
  default     = false
  description = "When true, checks resource existence before creating. Use for brownfield imports."
}

variable "precheck_billing_access" {
  type        = bool
  default     = false
  description = "When true, billing modules call checkAccess API before creating resources."
}

variable "docker_available" {
  type        = bool
  default     = true
  description = "Whether Docker is running. Required for k8s_kind_clusters."
}

# ── Remote state ─────────────────────────────────────────────────────────────

variable "remote_states" {
  type        = any
  default     = {}
  description = "Map of remote state outputs to expose in ref: resolution context."
}

variable "remote_state_backend" {
  type = object({
    resource_group_name  = string
    storage_account_name = string
    container_name       = string
    use_azuread_auth     = optional(bool, true)
  })
  default     = null
  description = "Azure Storage backend config for remote state lookups."
}

variable "remote_state_keys" {
  type        = map(string)
  default     = {}
  description = "Map of logical name to state key for remote state data sources."
}

# ── External references ──────────────────────────────────────────────────────

variable "externals" {
  type        = any
  default     = {}
  description = "Static external references — data about resources not managed by this Terraform state."
}

# ── Kubernetes ───────────────────────────────────────────────────────────────

variable "k8s_cluster_credentials" {
  type = map(object({
    endpoint = string
    token    = string
  }))
  default     = {}
  description = "Per-cluster K8s API credentials. Map keys match k8s_kind_clusters YAML keys."
}

variable "k8s_aks_cluster_credentials" {
  type = map(object({
    endpoint = string
    token    = string
  }))
  default     = {}
  description = "Per-AKS-cluster K8s API credentials. Map keys match AKS cluster names."
}

# ── TLS ──────────────────────────────────────────────────────────────────────

variable "tls_private_keys" {
  type = map(object({
    algorithm  = optional(string, "RSA")
    rsa_bits   = optional(number, 4096)
    ecdsa_curve = optional(string, null)
  }))
  default     = {}
  description = "Map of TLS private keys to generate."
}
