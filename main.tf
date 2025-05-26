data "azurerm_client_config" "current" {
  
}

resource "azurerm_resource_group" "rg" {
  name = "${var.env}-${var.rg_name}"
  location = var.location
}

resource "random_id" "id" {
  byte_length = 4
}

resource "azurerm_key_vault" "kv" {
  name = "${var.env}-${var.kv_name}-${random_id.id.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id = data.azurerm_client_config.current.tenant_id
  location = azurerm_resource_group.rg.location
  sku_name = var.kv_sku_name
  enable_rbac_authorization = true
}

resource "random_password" "vm-password" {
  length = 16
  special = true
  override_special = "!#$%&,."
}

resource "azurerm_key_vault_secret" "kv-vm-secret" {
  key_vault_id = azurerm_key_vault.kv.id
  name = var.kv_vm_secret_name
  value = random_password.vm-password.result
}

resource "azurerm_virtual_network" "vnet" {
  name = "${var.env}-vnet"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_subnet" "sub" {
  name = "${var.env}-internal"
  address_prefixes = ["10.0.2.0/24"]
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_interface" "nic" {
  name = "${var.env}-example-nic"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.sub.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "windows-vm" {
  name = "${var.env}-${var.vm_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  size = "Standard_F2"
  admin_username = "adminuser"
  admin_password = azurerm_key_vault_secret.kv-vm-secret.value
  os_disk {
    caching = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer = "WindowsServer"
    sku = "2019-Datacenter"
    version = "latest"
  }
}