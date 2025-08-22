resource "tls_private_key" "jump" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "azurerm_linux_virtual_machine" "jump" {
  name                            = local.vm_jump
  location                        = var.location
  resource_group_name             = var.rg_name
  size                            = var.vm_jump_size
  admin_username                  = var.vm_jump_admin
  network_interface_ids           = [azurerm_network_interface.nic_jump.id]
  disable_password_authentication = true
  admin_ssh_key {
    username   = var.vm_jump_admin
    public_key = tls_private_key.jump.public_key_openssh
  }
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
}

data "azurerm_storage_account" "st_arti" {
  name                = module.st_arti.name
  resource_group_name = var.rg_name
  # Ensure the storage account exists before reading keys; defers data read until apply
  depends_on = [module.st_arti]
}

resource "azurerm_container_group" "arti" {
  name                = var.arti_cg
  location            = var.location
  resource_group_name = var.rg_name
  ip_address_type     = "Private"
  os_type             = "Linux"
  subnet_ids          = [azurerm_subnet.snet_arti_aci.id]
  depends_on          = [azurerm_storage_share.arti]

  timeouts {
    create = "90m"
    update = "90m"
  }
  container {
    name   = var.arti_cg
    image  = var.arti_image
    cpu    = var.arti_cpu
    memory = var.arti_mem
    ports { port = 8081 }
    ports { port = 8082 }
    # Health checks for Artifactory
    readiness_probe {
      http_get {
        path   = "/artifactory/api/system/ping"
        port   = 8081
          scheme = "http"
      }
      initial_delay_seconds = 120
      period_seconds        = 10
      failure_threshold     = 6
      success_threshold     = 1
      timeout_seconds       = 5
    }
    liveness_probe {
      http_get {
        path   = "/artifactory/api/system/ping"
        port   = 8081
          scheme = "http"
      }
      initial_delay_seconds = 180
      period_seconds        = 20
      failure_threshold     = 6
      success_threshold     = 1
      timeout_seconds       = 5
    }
    volume {
      name                 = "azurefile"
      mount_path           = "/var/opt/jfrog/artifactory"
      read_only            = false
      storage_account_name = module.st_arti.name
      storage_account_key  = data.azurerm_storage_account.st_arti.primary_access_key
      share_name           = var.arti_share
    }
  }
}
