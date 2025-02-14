terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.114.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "116585fb-86e9-44dc-9906-4ee20541e1d1"
  client_id = "4343e2ad-8fb9-462a-86a1-b7dd8a75be5b"
  client_secret = "~wK8Q~g3a4yHG8vkZawXskGXOGVXyurbsLsJtbP_"
  tenant_id = "f9b2ba39-8b32-418e-af0f-e02a6caa9bea"
  features {}
}


locals {
  resource_group="app-grp"
  location="West Europe"
}




resource "azurerm_resource_group" "app_grp" {
 name=local.resource_group
 location=local.location
}

resource "azurerm_service_plan" "svc_plan1000" {
  name                = "svc-plan1000"
  location            = local.location
  resource_group_name = local.resource_group
  os_type = "Linux"
  sku_name="B1"


}

resource "azurerm_linux_web_app" "linux_webapp" {
  name                = "linux-app-14082024"
  location            = local.location
  resource_group_name = local.resource_group
  service_plan_id = azurerm_service_plan.svc_plan1000.id

  site_config {}


}



resource "azurerm_virtual_network" "app_network" {
  name                = "app-network"
  location            = local.location
  resource_group_name = azurerm_resource_group.app_grp.name
  address_space       = ["10.0.0.0/16"]

}

resource "azurerm_subnet" "SubnetA" {
  name                 = "SubnetA"
  resource_group_name  = local.resource_group
  virtual_network_name = azurerm_virtual_network.app_network.name
  address_prefixes     = ["10.0.1.0/24"]

    depends_on = [
    azurerm_virtual_network.app_network
    ]
}





resource "azurerm_network_interface" "app_interface" {
  name                = "app-interface"
  location            = local.location
  resource_group_name = local.resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.app_public_ip.id
  }

  depends_on = [ 
    azurerm_virtual_network.app_network, 
    azurerm_public_ip.app_public_ip,
    azurerm_subnet.SubnetA

   ]
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                = "linuxvm"
  resource_group_name = local.resource_group
  location            = local.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  admin_password = "Azure@123"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.app_interface.id
  ]


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  depends_on = [ 
    azurerm_network_interface.app_interface
  ]

}


resource "azurerm_public_ip" "app_public_ip" {
  name                    = "app-public-ip"
  location                = local.location
  resource_group_name     = local.resource_group
  allocation_method       = "Static"

  depends_on = [azurerm_resource_group.app_grp]
}





test