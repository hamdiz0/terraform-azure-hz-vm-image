# create a resource group
resource "azurerm_resource_group" "image_gen" {
  name     = var.resource_group_name
  location = var.location
}

# create a virtual network
resource "azurerm_virtual_network" "main" {
  name                = "${var.custom_image_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.image_gen.location
  resource_group_name = azurerm_resource_group.image_gen.name
}

# create a subnet
resource "azurerm_subnet" "main" {
  name                 = "${var.custom_image_name}-subnet"
  resource_group_name  = azurerm_resource_group.image_gen.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# create a public ip for ssh connection
resource "azurerm_public_ip" "custom_image_pip" {
  name                = "${var.custom_image_name}-pip"
  location            = azurerm_resource_group.image_gen.location
  resource_group_name = azurerm_resource_group.image_gen.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# create a network interface
resource "azurerm_network_interface" "custom_image_nic" {
  name                = "${var.custom_image_name}-nic"
  location            = azurerm_resource_group.image_gen.location
  resource_group_name = azurerm_resource_group.image_gen.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.custom_image_pip.id
  }
}

# associate the nsg with the nic
resource "azurerm_network_interface_security_group_association" "custom_image_nic_nsg" {
  network_interface_id      = azurerm_network_interface.custom_image_nic.id
  network_security_group_id = azurerm_network_security_group.custom_image_sg.id
}

# create an instance and execute the script
resource "azurerm_linux_virtual_machine" "custom_image_instance" {
  name                = "${var.custom_image_name}-vm"
  resource_group_name = azurerm_resource_group.image_gen.name
  location            = azurerm_resource_group.image_gen.location
  size                = var.vm_size
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.custom_image_nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(var.public_ssh_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.base_image.publisher
    offer     = var.base_image.offer
    sku       = var.base_image.sku
    version   = var.base_image.version
  }

  # connect to the instance via ssh
  connection {
    type        = "ssh"
    user        = "azureuser"
    private_key = file(var.private_ssh_key_path)
    host        = azurerm_public_ip.custom_image_pip.ip_address
  }

  # copy the scripts to the instance
  provisioner "file" {
    source      = var.script_path
    destination = "/home/azureuser/${basename(var.script_path)}"
  }

  # execute the scripts
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/azureuser/${basename(var.script_path)}",
      "sudo bash /home/azureuser/${basename(var.script_path)}",
    ]
  }

  depends_on = [azurerm_network_interface_security_group_association.custom_image_nic_nsg]
}

# deprovision, deallocate and generalize the vm for image capture
resource "null_resource" "generalize_vm" {
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "azureuser"
      private_key = file(var.private_ssh_key_path)
      host        = azurerm_public_ip.custom_image_pip.ip_address
    }

    inline = [
      "sudo waagent -deprovision+user -force",
    ]
  }

  provisioner "local-exec" {
    command = <<EOT
      az vm deallocate --resource-group ${azurerm_resource_group.image_gen.name} --name ${azurerm_linux_virtual_machine.custom_image_instance.name}
      az vm generalize --resource-group ${azurerm_resource_group.image_gen.name} --name ${azurerm_linux_virtual_machine.custom_image_instance.name}
    EOT
  }

  depends_on = [azurerm_linux_virtual_machine.custom_image_instance]
}

# create an image from the generalized vm
resource "azurerm_image" "custom_image" {
  name                      = var.custom_image_name
  location                  = azurerm_resource_group.image_gen.location
  resource_group_name       = azurerm_resource_group.image_gen.name
  source_virtual_machine_id = azurerm_linux_virtual_machine.custom_image_instance.id
  hyper_v_generation        = "V2"

  depends_on = [null_resource.generalize_vm]
}

# use azure cli to delete all resources except the resource group and image
resource "null_resource" "delete_resources" {
  count = var.delete_resources ? 1 : 0
  provisioner "local-exec" {
    command = <<EOT
      OS_DISK_NAME=$(az vm show --resource-group ${azurerm_resource_group.image_gen.name} --name ${azurerm_linux_virtual_machine.custom_image_instance.name} --query "storageProfile.osDisk.name" -o tsv)
      az vm delete --resource-group ${azurerm_resource_group.image_gen.name} --name ${azurerm_linux_virtual_machine.custom_image_instance.name} --yes
      az disk delete --resource-group ${azurerm_resource_group.image_gen.name} --name $OS_DISK_NAME --yes --no-wait false || true
      az network nic delete --resource-group ${azurerm_resource_group.image_gen.name} --name ${azurerm_network_interface.custom_image_nic.name}
      az network public-ip delete --resource-group ${azurerm_resource_group.image_gen.name} --name ${azurerm_public_ip.custom_image_pip.name}
      az network nsg delete --resource-group ${azurerm_resource_group.image_gen.name} --name ${azurerm_network_security_group.custom_image_sg.name}
      az network vnet subnet delete --resource-group ${azurerm_resource_group.image_gen.name} --vnet-name ${azurerm_virtual_network.main.name} --name ${azurerm_subnet.main.name}
      az network vnet delete --resource-group ${azurerm_resource_group.image_gen.name} --name ${azurerm_virtual_network.main.name}
    EOT
  }
  depends_on = [azurerm_image.custom_image]
}
