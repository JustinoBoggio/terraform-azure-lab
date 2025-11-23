locals {
  tenant_id   = "004b1179-227e-44f2-b759-e9f05b015b7b"
  owner       = "justino"
  project     = "terraform-azure-lab"
  environment = "governance"

  common_tags = {
    owner       = local.owner
    project     = local.project
    environment = local.environment
  }
}

data "azurerm_subscription" "current" {}

# --------------------------------------------------------------
# Policy 1: deny resource groups without required tags
# --------------------------------------------------------------

resource "azurerm_policy_definition" "deny_rg_without_tags" {
  name         = "deny-rg-without-required-tags"
  display_name = "Deny resource groups without required tags"
  policy_type  = "Custom"
  mode         = "All"

  metadata = jsonencode({
    category = "Tags"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Resources/subscriptions/resourceGroups"
        },
        {
          anyOf = [
            {
              field  = "tags['environment']"
              exists = "false"
            },
            {
              field  = "tags['owner']"
              exists = "false"
            }
          ]
        }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

resource "azurerm_subscription_policy_assignment" "deny_rg_without_tags" {
  name                 = "deny-rg-without-required-tags"
  display_name         = "Deny resource groups without required tags"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = azurerm_policy_definition.deny_rg_without_tags.id

  description = "Requires environment and owner tags on all resource groups in this subscription"
}

# --------------------------------------------------------------
# Policy 2: allow only eastus as a location
# --------------------------------------------------------------

resource "azurerm_policy_definition" "only_eastus" {
  name         = "only-eastus-locations"
  display_name = "Allow only eastus as a location"
  policy_type  = "Custom"
  mode         = "All"

  metadata = jsonencode({
    category = "Location"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field     = "type"
          notEquals = "Microsoft.Resources/subscriptions/resourceGroups"
        },
        {
          field     = "location"
          notEquals = "eastus"
        }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

resource "azurerm_subscription_policy_assignment" "only_eastus" {
  name                 = "only-eastus-locations"
  display_name         = "Allow only eastus as a location"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = azurerm_policy_definition.only_eastus.id

  description = "Prevents creation of resources outside eastus in this subscription"
}

# --------------------------------------------------------------
# Policy 3: Enforce environment and owner tags on all resources
# --------------------------------------------------------------

resource "azurerm_policy_definition" "enforce_resource_tags" {
  name         = "enforce-resource-tags-environment-owner"
  display_name = "Enforce environment and owner tags on all resources"
  policy_type  = "Custom"
  mode         = "All"

  metadata = jsonencode({
    category = "Tags"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field     = "type"
          notEquals = "Microsoft.Resources/subscriptions/resourceGroups"
        },
        {
          anyOf = [
            {
              field  = "tags['environment']"
              exists = "false"
            },
            {
              field  = "tags['owner']"
              exists = "false"
            }
          ]
        }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

data "azurerm_resource_group" "rg_core_dev" {
  name = "rg-core-dev"
}

data "azurerm_resource_group" "rg_core_uat" {
  name = "rg-core-uat"
}

resource "azurerm_resource_group_policy_assignment" "enforce_resource_tags_dev" {
  name                 = "enforce-resource-tags-environment-owner-dev"
  display_name         = "Enforce environment and owner tags on all resources in rg-core-dev"
  resource_group_id    = data.azurerm_resource_group.rg_core_dev.id
  policy_definition_id = azurerm_policy_definition.enforce_resource_tags.id

  description = "Requires environment and owner tags on all resources in rg-core-dev"
}

resource "azurerm_resource_group_policy_assignment" "enforce_resource_tags_uat" {
  name                 = "enforce-resource-tags-environment-owner-uat"
  display_name         = "Enforce environment and owner tags on all resources in rg-core-uat"
  resource_group_id    = data.azurerm_resource_group.rg_core_uat.id
  policy_definition_id = azurerm_policy_definition.enforce_resource_tags.id

  description = "Requires environment and owner tags on all resources in rg-core-uat"
}