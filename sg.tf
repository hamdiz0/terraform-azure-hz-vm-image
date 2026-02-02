# security group for ssh
resource "azurerm_network_security_group" "custom_image_sg" {
  name                = "${var.custom_image_name}-nsg"
  location            = azurerm_resource_group.image_gen.location
  resource_group_name = azurerm_resource_group.image_gen.name
}

# ssh inbound rule
resource "azurerm_network_security_rule" "ssh_ingress" {
  name                        = "allow_ssh"
  resource_group_name         = azurerm_resource_group.image_gen.name
  network_security_group_name = azurerm_network_security_group.custom_image_sg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  description                 = "allow ssh"
}

# allow all outbound
resource "azurerm_network_security_rule" "egress" {
  name                        = "allow_all_outbound"
  resource_group_name         = azurerm_resource_group.image_gen.name
  network_security_group_name = azurerm_network_security_group.custom_image_sg.name
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  description                 = "Allow all outbound traffic"

  lifecycle {
    ignore_changes = all
  }
}
