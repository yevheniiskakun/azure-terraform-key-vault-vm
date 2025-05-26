data "azurerm_client_config" "current" {
  
}

resource "azurerm_resource_group" "rg" {
  name = "${var.env}-${ver.rg_name}"
  location = var.location
}

resource "random_id" "name" {
  byte_length = 4
}

resource "azurerm_key_vault" "kv" {
  name = "${var.env}-${var.kv_name}-${random_id.id.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id = data.azurerm_client_config.current.tenant_id
  location = azurerm_resource_group.rg.name
  sku_name = var.kv_sku_name
}