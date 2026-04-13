# ── Root Module ───────────────────────────────────────────────────────────────
#
# Thin wrapper around the upstream terraform-rest-galaxy module.
# Reads the YAML config file and delegates all resource management to the
# upstream module.
#
# Usage:
#   terraform init \
#     -backend-config="storage_account_name=<tfstate-storage-account>" \
#     -backend-config="resource_group_name=<tfstate-resource-group>" \
#     -backend-config="container_name=terraform" \
#     -backend-config="key=<org>/<env>/<region>/<workload>/terraform.tfstate"
#
#   terraform plan -var="config_file=configurations/env-dev/config.yaml"

module "infrastructure" {
  source  = "LaurentLesle/galaxy/rest"
  version = "1.4.3"

  # Config
  config_file = var.config_file

  # Azure authentication
  azure_access_token  = var.azure_access_token
  azure_refresh_token = var.azure_refresh_token
  azure_token_url     = var.azure_token_url
  arm_tenant_tokens   = var.arm_tenant_tokens

  # Graph authentication
  graph_access_token  = var.graph_access_token
  graph_refresh_token = var.graph_refresh_token
  graph_token_url     = var.graph_token_url

  # GitHub authentication
  github_token = var.github_token

  # Azure defaults
  subscription_id  = var.subscription_id
  tenant_id        = var.tenant_id
  default_location = var.default_location
  caller_object_id = var.caller_object_id

  # Behavior flags
  fail_on_warning        = var.fail_on_warning
  check_existance        = var.check_existance
  precheck_billing_access = var.precheck_billing_access
  docker_available       = var.docker_available

  # Remote state
  remote_states        = var.remote_states
  remote_state_backend = var.remote_state_backend
  remote_state_keys    = var.remote_state_keys

  # External references
  externals = var.externals

  # Kubernetes
  k8s_cluster_credentials     = var.k8s_cluster_credentials
  k8s_aks_cluster_credentials = var.k8s_aks_cluster_credentials

  # TLS
  tls_private_keys = var.tls_private_keys
}
