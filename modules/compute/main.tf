# Network Security Group for Artifactory VM
resource "azurerm_network_security_group" "artifactory_nsg" {
  name                = "${var.name_prefix}-artifactory-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow Artifactory HTTP traffic
  security_rule {
    name                       = "Allow-Artifactory-HTTP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8082"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Allow SSH
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Network Interface for Artifactory VM
resource "azurerm_network_interface" "artifactory_nic" {
  name                = "${var.name_prefix}-artifactory-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.compute_subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

# Associate NSG with Artifactory NIC
resource "azurerm_network_interface_security_group_association" "artifactory_nsg_association" {
  network_interface_id      = azurerm_network_interface.artifactory_nic.id
  network_security_group_id = azurerm_network_security_group.artifactory_nsg.id
}

# Artifactory VM (Ubuntu with Docker)
resource "azurerm_linux_virtual_machine" "artifactory_vm" {
  name                = "${var.name_prefix}-artifactory-vm"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = "Standard_B4ms"

  disable_password_authentication = false
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.artifactory_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Custom script to install Docker and Artifactory
  # The install script is a standalone bash script with internal defaults; no Terraform templating required.
  # Using filebase64 avoids template interpolation conflicts with bash variable syntax (e.g. ${ARTI_VERSION}).
  custom_data = filebase64("${path.module}/scripts/install-artifactory.sh")

  tags = var.tags
}

# Network Security Group for Windows VM
resource "azurerm_network_security_group" "windows_nsg" {
  name                = "${var.name_prefix}-windows-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow RDP (for Bastion)
  security_rule {
    name                       = "Allow-RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Network Interface for Windows VM
resource "azurerm_network_interface" "windows_nic" {
  name                = "${var.name_prefix}-jumpbox-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.compute_subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

# Associate NSG with Windows NIC
resource "azurerm_network_interface_security_group_association" "windows_nsg_association" {
  network_interface_id      = azurerm_network_interface.windows_nic.id
  network_security_group_id = azurerm_network_security_group.windows_nsg.id
}

# Windows Jumpbox VM
resource "azurerm_windows_virtual_machine" "jumpbox_vm" {
  name                = "${var.name_prefix}-jumpbox-vm"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = "Standard_B2s"
  # Windows computer name must be <= 15 characters. Derive a short, deterministic name.
  computer_name = "jbox-${substr(replace(var.name_prefix, "-", ""), 0, 9)}"

  admin_username = var.admin_username
  admin_password = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.windows_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }

  tags = var.tags
}

/* Remote Windows setup script now downloaded at apply time.
   To force re-run change windows_setup_rerun_token variable. */

locals {
  windows_setup_script_url = "https://raw.githubusercontent.com/brynsp/lab-azml-artifactory/refs/heads/main/modules/compute/scripts/setup-windows.ps1"
}

# Install Docker and Azure CLI on Windows VM
resource "azurerm_virtual_machine_extension" "windows_setup" {
  name                 = "windows-setup"
  virtual_machine_id   = azurerm_windows_virtual_machine.jumpbox_vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Bypass -Command \"Invoke-WebRequest -UseBasicParsing -Uri '${local.windows_setup_script_url}' -OutFile C:\\setup.ps1; powershell -ExecutionPolicy Bypass -File C:\\setup.ps1\""
  })

  # Hash only uses rerun token now (remote file fetched each time extension recreated)
  protected_settings = jsonencode({
    script_hash = sha256(var.windows_setup_rerun_token)
  })

  tags = var.tags
}

# Public IP for Bastion
resource "azurerm_public_ip" "bastion_pip" {
  count = var.enable_bastion ? 1 : 0

  name                = "${var.name_prefix}-bastion-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

# Azure Bastion
resource "azurerm_bastion_host" "bastion" {
  count = var.enable_bastion ? 1 : 0

  name                = "${var.name_prefix}-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion_pip[0].id
  }

  tags = var.tags
}
