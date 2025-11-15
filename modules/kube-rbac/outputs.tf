output "deployer_service_account_name" {
  description = "Service account name for app deployer"
  value       = kubernetes_service_account.app_deployer.metadata[0].name
}

output "viewer_service_account_name" {
  description = "Service account name for app viewer"
  value       = kubernetes_service_account.app_viewer.metadata[0].name
}