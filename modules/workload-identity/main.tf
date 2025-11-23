resource "azurerm_user_assigned_identity" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "this" {
  name                = "${var.name}-fic"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.this.id

  issuer   = var.kubernetes_oidc_issuer_url
  audience = ["api://AzureADTokenExchange"]
  subject  = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}
