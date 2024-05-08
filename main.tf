resource "azurerm_resource_group" "mba-rg" {
  name     = var.resource_group
  location = var.location
}

resource "azurerm_application_security_group" "mba-asg" {
  name                = "app-backend-asg"
  location            = azurerm_resource_group.mba-rg.location
  resource_group_name = azurerm_resource_group.mba-rg.name
}

resource "azurerm_network_security_group" "mba-nsg" {
  name                = "app-vnet-nsg"
  location            = azurerm_resource_group.mba-rg.location
  resource_group_name = azurerm_resource_group.mba-rg.name
}

resource "azurerm_network_security_rule" "mba-rule1" {
  name                                       = "AllowSSH"
  priority                                   = 100
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "22"
  source_address_prefix                      = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.mba-asg.id]
  resource_group_name                        = azurerm_resource_group.mba-rg.name
  network_security_group_name                = azurerm_network_security_group.mba-nsg.name
}


resource "azurerm_virtual_network" "mba-vnet1" {
  name                = "app-vnet"
  location            = azurerm_resource_group.mba-rg.location
  resource_group_name = azurerm_resource_group.mba-rg.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "mba-vnet1-s1" {
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.mba-rg.name
  virtual_network_name = azurerm_virtual_network.mba-vnet1.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource "azurerm_subnet" "mba-vnet1-s2" {
  name                 = "backend"
  resource_group_name  = azurerm_resource_group.mba-rg.name
  virtual_network_name = azurerm_virtual_network.mba-vnet1.name
  address_prefixes     = ["10.1.1.0/24"]
}
resource "azurerm_subnet" "mba-vnet1-s3" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.mba-rg.name
  virtual_network_name = azurerm_virtual_network.mba-vnet1.name
  address_prefixes     = ["10.1.63.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "mba-sga" {
  subnet_id                 = azurerm_subnet.mba-vnet1-s2.id
  network_security_group_id = azurerm_network_security_group.mba-nsg.id
}

resource "azurerm_virtual_network" "mba-vnet2" {
  name                = "shared-services-vnet"
  location            = azurerm_resource_group.mba-rg.location
  resource_group_name = azurerm_resource_group.mba-rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "mba-vnet2-s1" {
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.mba-rg.name
  virtual_network_name = azurerm_virtual_network.mba-vnet2.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_virtual_network_peering" "mba-pa1" {
  name                      = "app-vnet-to-sharedservices"
  resource_group_name       = azurerm_resource_group.mba-rg.name
  virtual_network_name      = azurerm_virtual_network.mba-vnet1.name
  remote_virtual_network_id = azurerm_virtual_network.mba-vnet2.id
}

resource "azurerm_virtual_network_peering" "mba-pa2" {
  name                      = "sharedservices-to-app-vnet"
  resource_group_name       = azurerm_resource_group.mba-rg.name
  virtual_network_name      = azurerm_virtual_network.mba-vnet2.name
  remote_virtual_network_id = azurerm_virtual_network.mba-vnet1.id
}

resource "azurerm_public_ip" "mba-ip1" {
  name                = var.VM1_ip_name
  resource_group_name = azurerm_resource_group.mba-rg.name
  location            = azurerm_resource_group.mba-rg.location
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "mba-ip2" {
  name                = var.VM2_ip_name
  resource_group_name = azurerm_resource_group.mba-rg.name
  location            = azurerm_resource_group.mba-rg.location
  allocation_method   = "Dynamic"
}
resource "azurerm_public_ip" "mba-ip3" {
  name                = var.fw_ip_name
  resource_group_name = azurerm_resource_group.mba-rg.name
  location            = azurerm_resource_group.mba-rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_private_dns_zone" "mba-dnsz1" {
  name                = "contoso.com"
  resource_group_name = azurerm_resource_group.mba-rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "mba-dvlink1" {
  name                  = "app-vnet-link"
  resource_group_name   = azurerm_resource_group.mba-rg.name
  private_dns_zone_name = azurerm_private_dns_zone.mba-dnsz1.name
  virtual_network_id    = azurerm_virtual_network.mba-vnet1.id
}

resource "azurerm_private_dns_a_record" "mba-dnsr1" {
  name                = "backend"
  zone_name           = azurerm_private_dns_zone.mba-dnsz1.name
  resource_group_name = azurerm_resource_group.mba-rg.name
  ttl                 = 1
  records             = ["10.1.1.4"]
}

/*
resource "azurerm_firewall_policy" "mba-fwp" {
  name                = "fw-policy"
  resource_group_name = azurerm_resource_group.mba-rg.name
  location            = azurerm_resource_group.mba-rg.location
}

resource "azurerm_firewall_policy_rule_collection_group" "mba-fwrcg" {
  name               = "fw-policy-rule-collection"
  firewall_policy_id = azurerm_firewall_policy.mba-fwp.id
  priority           = 200
  application_rule_collection {
    name     = "app-vnet-fw-rule-collection"
    priority = 201
    action   = "Allow"
    rule {
      name = "AllowAzurePipelines"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["10.1.0.0/23"]
      destination_fqdns = ["dev.azure.com", "azure.microsoft.com"]
    }
  }

  network_rule_collection {
    name     = "app-vnet-fw-nrc-dns"
    priority = 202
    action   = "Allow"
    rule {
      name                  = "AllowDns"
      protocols             = ["UDP"]
      source_addresses      = ["10.1.0.0/23"]
      destination_addresses = ["1.1.1.1", "1.0.0.1"]
      destination_ports     = ["53"]
    }
  }
}

resource "azurerm_firewall" "mba-fw" {
  name                = "app-vnet-firewall"
  location            = azurerm_resource_group.mba-rg.location
  resource_group_name = azurerm_resource_group.mba-rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.mba-fwp.id

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.mba-vnet1-s3.id
    public_ip_address_id = azurerm_public_ip.mba-ip3.id
  }
}

resource "azurerm_route_table" "mba-fwrt" {
  name                = "app-vnet-firewall-rt"
  location            = azurerm_resource_group.mba-rg.location
  resource_group_name = azurerm_resource_group.mba-rg.name
}

resource "azurerm_subnet_route_table_association" "mba-rta1" {
  subnet_id      = azurerm_subnet.mba-vnet1-s1.id
  route_table_id = azurerm_route_table.mba-fwrt.id
}

resource "azurerm_subnet_route_table_association" "mba-rta2" {
  subnet_id      = azurerm_subnet.mba-vnet1-s2.id
  route_table_id = azurerm_route_table.mba-fwrt.id
}

resource "azurerm_route" "mba-r1" {
  name                   = "outbound-firewall"
  resource_group_name    = azurerm_resource_group.mba-rg.name
  route_table_name       = azurerm_route_table.mba-fwrt.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.mba-fw.ip_configuration[0].private_ip_address
}
*/


resource "azurerm_network_interface" "mba-nic1" {
  name                = var.VM1_nic_name
  location            = azurerm_resource_group.mba-rg.location
  resource_group_name = azurerm_resource_group.mba-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.mba-vnet1-s1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.0.4"
    public_ip_address_id          = azurerm_public_ip.mba-ip1.id
  }
}

resource "azurerm_network_interface" "mba-nic2" {
  name                = var.VM2_nic_name
  location            = azurerm_resource_group.mba-rg.location
  resource_group_name = azurerm_resource_group.mba-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.mba-vnet1-s2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.1.4"
    public_ip_address_id          = azurerm_public_ip.mba-ip2.id
  }
}

resource "azurerm_linux_virtual_machine" "mba-vm1" {
  name                  = var.VM1_name
  resource_group_name   = azurerm_resource_group.mba-rg.name
  location              = azurerm_resource_group.mba-rg.location
  size                  = var.VM1_size
  admin_username        = var.VM1_user
  network_interface_ids = [azurerm_network_interface.mba-nic1.id]

  admin_ssh_key {
    username   = var.VM1_user
    public_key = file(var.SSH_pk)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "mba-vm2" {
  name                  = var.VM2_name
  resource_group_name   = azurerm_resource_group.mba-rg.name
  location              = azurerm_resource_group.mba-rg.location
  size                  = var.VM2_size
  admin_username        = var.VM2_user
  network_interface_ids = [azurerm_network_interface.mba-nic2.id]

  admin_ssh_key {
    username   = var.VM2_user
    public_key = file(var.SSH_pk)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
