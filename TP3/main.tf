provider "azurerm" {
  features {}
  subscription_id = "c7ce0e71-911f-4dc1-b702-3ac0c4b21986" 
}

resource "azurerm_resource_group" "main" {
  name     = "tp3-ansible-resources"
  location = "West Europe"
}

resource "azurerm_virtual_network" "main" {
  name                = "tp3-ansible-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 🔹 IP publique pour VM1
resource "azurerm_public_ip" "vm1_pip" {
  name                = "tp3-ansible-vm1-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
}

# 🔹 IP publique pour VM2
resource "azurerm_public_ip" "vm2_pip" {
  name                = "tp3-ansible-vm2-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
}

# 🔹 Interface réseau VM1
resource "azurerm_network_interface" "vm1_nic" {
  name                = "tp3-ansible-vm1-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm1_pip.id
  }
}

# 🔹 Interface réseau VM2
resource "azurerm_network_interface" "vm2_nic" {
  name                = "tp3-ansible-vm2-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm2_pip.id
  }
}

# 🔹 Interface réseau VM3 (Sans IP publique)
resource "azurerm_network_interface" "vm3_nic" {
  name                = "tp3-ansible-vm3-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

# 🔹 Règle de sécurité pour autoriser SSH et MariaDB/MySQL
resource "azurerm_network_security_group" "ssh" {
  name                = "tp3-ansible-ssh"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "22"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowMariaDB"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "10.0.1.0/24"  # Seules les VMs du LAN peuvent accéder à la DB
    destination_port_range     = "3306"
    destination_address_prefix = "*"
  }
}

# 🔹 Associer les VMs à la règle de sécurité SSH
resource "azurerm_network_interface_security_group_association" "vm1" {
  network_interface_id      = azurerm_network_interface.vm1_nic.id
  network_security_group_id = azurerm_network_security_group.ssh.id
}

resource "azurerm_network_interface_security_group_association" "vm2" {
  network_interface_id      = azurerm_network_interface.vm2_nic.id
  network_security_group_id = azurerm_network_security_group.ssh.id
}

resource "azurerm_network_interface_security_group_association" "vm3" {
  network_interface_id      = azurerm_network_interface.vm3_nic.id
  network_security_group_id = azurerm_network_security_group.ssh.id
}

# 🔹 VM1 (Serveur Web)
resource "azurerm_linux_virtual_machine" "vm1" {
  name                  = "tp3-ansible-vm1"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  size                  = "Standard_B1s"
  admin_username        = "antoine"
  network_interface_ids = [azurerm_network_interface.vm1_nic.id]

  admin_ssh_key {
    username   = "antoine"
    public_key = file("C:\\Users\\antoi\\.ssh\\id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}

# 🔹 VM2 (Serveur Web)
resource "azurerm_linux_virtual_machine" "vm2" {
  name                  = "tp3-ansible-vm2"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  size                  = "Standard_B1s"
  admin_username        = "antoine"
  network_interface_ids = [azurerm_network_interface.vm2_nic.id]

  admin_ssh_key {
    username   = "antoine"
    public_key = file("C:\\Users\\antoi\\.ssh\\id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}

# 🔹 VM3 (Database)
resource "azurerm_linux_virtual_machine" "vm3" {
  name                  = "tp3-ansible-vm3"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  size                  = "Standard_B1s"
  admin_username        = "antoine"
  network_interface_ids = [azurerm_network_interface.vm3_nic.id]

  admin_ssh_key {
    username   = "antoine"
    public_key = file("C:\\Users\\antoi\\.ssh\\id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}