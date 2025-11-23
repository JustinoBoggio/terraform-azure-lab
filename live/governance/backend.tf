terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "statfstatejustino"
    container_name       = "tfstate-governance"
    key                  = "infra-governance.tfstate"

    # Use Azure AD + OIDC for the backend
    use_azuread_auth = true
    use_oidc         = true
    tenant_id        = "004b1179-227e-44f2-b759-e9f05b015b7b"
    client_id        = "54a7c81b-4ea0-4b56-aafa-6e3daa2a976d"
  }
}