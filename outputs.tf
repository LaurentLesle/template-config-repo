# ── Outputs ───────────────────────────────────────────────────────────────────

output "azure_values" {
  description = "Map of all Azure module outputs, keyed by config key."
  value       = module.infrastructure.azure_values
}

output "entraid_values" {
  description = "Map of all Entra ID module outputs."
  value       = module.infrastructure.entraid_values
}

output "github_values" {
  description = "Map of all GitHub module outputs."
  value       = module.infrastructure.github_values
}

output "k8s_values" {
  description = "Map of all Kubernetes module outputs."
  value       = module.infrastructure.k8s_values
}

output "externals" {
  description = "Validated external references (not managed by Terraform)."
  value       = module.infrastructure.externals
}
