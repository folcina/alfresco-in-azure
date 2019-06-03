provider "azurerm" {
   version = "~> 1.28.0"
   client_id = "${var.CLIENT_ID}",
   client_secret = "${var.CLIENT_SECRET}",
   subscription_id = "${var.SUBSCRIPTION_ID}",
   tenant_id = "${var.TENANT_ID}"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "deployment_rg" {
    name     = "${var.RESOURCE_GROUP_DEPLOYMENT}"
    location = "${var.LOCATION}"

    tags {
        environment = "Alfresco 6.1 Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "virtual-network" {
    name                = "alfresco-virtual-network"
    address_space       = ["10.0.0.0/16"]
    location            = "${var.LOCATION}"
    resource_group_name = "${azurerm_resource_group.deployment_rg.name}"

    tags {
        environment = "Alfresco 6.1 Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "backend_subnet" {
    name                 = "backend-subnet"
    resource_group_name  = "${azurerm_resource_group.deployment_rg.name}"
    virtual_network_name = "${azurerm_virtual_network.virtual-network.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create bastion public IP
resource "azurerm_public_ip" "bastion_public_ip" {
    name                         = "bastionIp"
    location                     = "${var.LOCATION}"
    resource_group_name          = "${azurerm_resource_group.deployment_rg.name}"
    allocation_method            = "Dynamic"

    tags {
        environment = "Alfresco 6.1 Demo"
    }
}

data "azurerm_public_ip" "bastion_public_ip" {
  name                = "${azurerm_public_ip.bastion_public_ip.name}"
  resource_group_name = "${azurerm_resource_group.deployment_rg.name}"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "${var.LOCATION}"
    resource_group_name = "${azurerm_resource_group.deployment_rg.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }

    security_rule {
        name                       = "Alfresco_HTTP"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8080"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "Zeppelin_HTTP"
        priority                   = 1004
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "9090"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "ActiveMQ-node0-admin"
        priority                   = 1005
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8161"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }

    security_rule {
        name                       = "ActiveMQ-node1-admin"
        priority                   = 1006
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8162"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }

    security_rule {
        name                       = "InsightEngine-node0-admin"
        priority                   = 1007
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8983"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }

    security_rule {
        name                       = "InsightEngine-node1-admin"
        priority                   = 1008
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8984"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }

    security_rule {
        name                       = "Transform-node0-libreoffice"
        priority                   = 1009
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8090"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }

    security_rule {
        name                       = "Transform-node0-pdf-renderer"
        priority                   = 1010
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8091"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }

    security_rule {
        name                       = "Transform-node0-imagemagick"
        priority                   = 1011
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8092"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }

    security_rule {
        name                       = "Transform-node0-tika"
        priority                   = 1012
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8093"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }

    security_rule {
        name                       = "Transform-node0-shared-file-store"
        priority                   = 1013
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8094"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }

    security_rule {
        name                       = "Transform-node0-router"
        priority                   = 1014
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8095"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }

    security_rule {
        name                       = "Transform-node1-libreoffice"
        priority                   = 1015
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8190"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }

    security_rule {
        name                       = "Transform-node1-pdf-renderer"
        priority                   = 1016
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8191"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }

    security_rule {
        name                       = "Transform-node1-imagemagick"
        priority                   = 1017
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8192"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }

    security_rule {
        name                       = "Transform-node1-tika"
        priority                   = 1018
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8193"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }

    security_rule {
        name                       = "Transform-node1-shared-file-store"
        priority                   = 1019
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8194"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }

    security_rule {
        name                       = "Transform-node1-router"
        priority                   = 1020
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8195"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }

    security_rule {
        name                       = "Activemq-node0-ssh"
        priority                   = 1021
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "2200"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }
    security_rule {
        name                       = "Activemq-node1-ssh"
        priority                   = 1022
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "2201"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }
    security_rule {
        name                       = "DB-ssh"
        priority                   = 1023
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "2202"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }
    security_rule {
        name                       = "Frontend-node0-ssh"
        priority                   = 1024
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "2203"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }
    security_rule {
        name                       = "Frontend-node1-ssh"
        priority                   = 1025
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "2204"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }
    security_rule {
        name                       = "Insight-node0-ssh"
        priority                   = 1026
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "2205"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }
    security_rule {
        name                       = "Insight-node1-ssh"
        priority                   = 1027
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "2206"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }
    security_rule {
        name                       = "Transform-node0-ssh"
        priority                   = 1028
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "2207"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }
    security_rule {
        name                       = "Transform-node1-ssh"
        priority                   = 1029
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "2208"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }

    security_rule {
        name                       = "Frontend-node0-jmx"
        priority                   = 1030
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "50500"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }

    security_rule {
        name                       = "Frontend-node1-jmx"
        priority                   = 1031
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "50501"
        source_address_prefix      = "*"
        destination_address_prefix = "${var.bastion_private_ip}"
    }

    tags {
        environment = "Alfresco 6.1 Demo"
    }
}


# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.deployment_rg.name}"
    }

    byte_length = 8
}

# Generate random text for a unique domain name
resource "random_id" "randomId_short" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.deployment_rg.name}"
    }

    byte_length = 4
}

# FQDN for the Alfresco LB with UNIQ-ID. By default it has the following format:
# [DOMAIN_NAME_LABEL env variable]-[uniq-id].[location].cloudapp.azure.com
# If [uniq-id] is not needed then comment this section and uncomment 'locals' section
# underneath
locals {
   alfresco_fqdn = "${var.DOMAIN_NAME_LABEL}-${random_id.randomId_short.hex}.${var.LOCATION}.${var.azure_cloudapp_dns}",
   alfresco_domain_label = "${var.DOMAIN_NAME_LABEL}-${random_id.randomId_short.hex}"
}

# FQDN for Alfresco LB without UNIQ-ID
#locals {
#   alfresco_fqdn = "${var.DOMAIN_NAME_LABEL}.${var.LOCATION}.${var.azure_cloudapp_dns}",
#   alfresco_domain_label = "${var.DOMAIN_NAME_LABEL}"
#}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.deployment_rg.name}"
    location                    = "${var.LOCATION}"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags {
        environment = "Alfresco 6.1 Demo"
    }
}

####### INTERNAL LOAD BALANCER (for Alfresco Search Services) #######

resource "azurerm_lb" "search-services-loadbalancer" {
  name                = "search-services-loadbalancer"
  resource_group_name = "${azurerm_resource_group.deployment_rg.name}"
  location            = "${var.LOCATION}"
  sku                 = "Basic"

  frontend_ip_configuration {
    name                 = "LoadBalancerSearchServices"
    subnet_id                     = "${azurerm_subnet.backend_subnet.id}"
    private_ip_address_allocation = "Static"
    private_ip_address = "${var.search_services_lb_private_ip}"
  }
}

resource "azurerm_lb_backend_address_pool" "loadbalancer_search_services_backend" {
  name                = "loadbalancer_search_services_backend"
  resource_group_name = "${azurerm_resource_group.deployment_rg.name}"
  loadbalancer_id     = "${azurerm_lb.search-services-loadbalancer.id}"
}
resource "azurerm_lb_probe" "loadbalancer_search_services_probe" {
  resource_group_name = "${azurerm_resource_group.deployment_rg.name}"
  loadbalancer_id     = "${azurerm_lb.search-services-loadbalancer.id}"
  name                = "SOLREndPointProbe"
  protocol            = "tcp"
  port                = 8983
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "SearchServicesEndPointListener" {
  resource_group_name            = "${azurerm_resource_group.deployment_rg.name}"
  loadbalancer_id                = "${azurerm_lb.search-services-loadbalancer.id}"
  name                           = "SearchServicesEndPointListener"
  protocol                       = "Tcp"
  frontend_port                  = 8983
  backend_port                   = 8983
  frontend_ip_configuration_name = "LoadBalancerSearchServices"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.loadbalancer_search_services_backend.id}"
  probe_id                       = "${azurerm_lb_probe.loadbalancer_search_services_probe.id}"
}

####### INTERNAL LOAD BALANCER (for Alfresco Repository) #######

resource "azurerm_lb" "internal-repository-loadbalancer" {
  name                = "internal-repository-loadbalancer"
  resource_group_name = "${azurerm_resource_group.deployment_rg.name}"
  location            = "${var.LOCATION}"
  sku                 = "Basic"
  frontend_ip_configuration {
    name                 = "InternalRepositoryLbConf"
    subnet_id                     = "${azurerm_subnet.backend_subnet.id}"
    private_ip_address_allocation = "Static"
    private_ip_address = "${var.internal_repository_lb_private_ip}"
  }
}
resource "azurerm_lb_backend_address_pool" "loadbalancer_internal_repository_backend" {
  name                = "loadbalancer_internal_repository_backend"
  resource_group_name = "${azurerm_resource_group.deployment_rg.name}"
  loadbalancer_id     = "${azurerm_lb.internal-repository-loadbalancer.id}"
}
resource "azurerm_lb_probe" "loadbalancer_internal_repository_probe" {
  resource_group_name = "${azurerm_resource_group.deployment_rg.name}"
  loadbalancer_id     = "${azurerm_lb.internal-repository-loadbalancer.id}"
  name                = "InternalRepoEndPointProbe"
  protocol            = "tcp"
  port                = 8080
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "InternalRepositoryEndPointListener" {
  resource_group_name            = "${azurerm_resource_group.deployment_rg.name}"
  loadbalancer_id                = "${azurerm_lb.internal-repository-loadbalancer.id}"
  name                           = "InternalRepositoryEndPointListener"
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = "InternalRepositoryLbConf"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.loadbalancer_internal_repository_backend.id}"
  probe_id                       = "${azurerm_lb_probe.loadbalancer_internal_repository_probe.id}"
  load_distribution              = "SourceIPProtocol"
}

####### INTERNAL LOAD BALANCER (for Transform Services) #######

resource "azurerm_lb" "transform-service-loadbalancer" {
  name                = "transform-service-loadbalancer"
  resource_group_name = "${azurerm_resource_group.deployment_rg.name}"
  location            = "${var.LOCATION}"
  sku                 = "Basic"
  frontend_ip_configuration {
    name                 = "TransformServiceLbConf"
    subnet_id                     = "${azurerm_subnet.backend_subnet.id}"
    private_ip_address_allocation = "Static"
    private_ip_address  = "${var.transform_service_lb_private_ip}"
  }
}

resource "azurerm_lb_backend_address_pool" "loadbalancer_transform_service_backend" {
  name                = "loadbalancer_transform_service_backend"
  resource_group_name = "${azurerm_resource_group.deployment_rg.name}"
  loadbalancer_id     = "${azurerm_lb.transform-service-loadbalancer.id}"
}

resource "azurerm_lb_probe" "loadbalancer_libreoffice_probe" {
  resource_group_name = "${azurerm_resource_group.deployment_rg.name}"
  loadbalancer_id     = "${azurerm_lb.transform-service-loadbalancer.id}"
  name                = "LibreofficeEndPointProbe"
  protocol            = "tcp"
  port                = 8090
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_probe" "loadbalancer_pdf_renderer_probe" {
  resource_group_name = "${azurerm_resource_group.deployment_rg.name}"
  loadbalancer_id     = "${azurerm_lb.transform-service-loadbalancer.id}"
  name                = "PdfRendererEndPointProbe"
  protocol            = "tcp"
  port                = 8091
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_probe" "loadbalancer_imagemagick_probe" {
  resource_group_name = "${azurerm_resource_group.deployment_rg.name}"
  loadbalancer_id     = "${azurerm_lb.transform-service-loadbalancer.id}"
  name                = "ImagemagickEndPointProbe"
  protocol            = "tcp"
  port                = 8092
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_probe" "loadbalancer_tika_probe" {
  resource_group_name = "${azurerm_resource_group.deployment_rg.name}"
  loadbalancer_id     = "${azurerm_lb.transform-service-loadbalancer.id}"
  name                = "TikaEndPointProbe"
  protocol            = "tcp"
  port                = 8093
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_probe" "loadbalancer_shared_file_store_probe" {
  resource_group_name = "${azurerm_resource_group.deployment_rg.name}"
  loadbalancer_id     = "${azurerm_lb.transform-service-loadbalancer.id}"
  name                = "InternalRepoEndPointProbe"
  protocol            = "tcp"
  port                = 8094
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "LibreofficeEndPointListener" {
  resource_group_name            = "${azurerm_resource_group.deployment_rg.name}"
  loadbalancer_id                = "${azurerm_lb.transform-service-loadbalancer.id}"
  name                           = "LibreofficeEndPointListener"
  protocol                       = "Tcp"
  frontend_port                  = 8090
  backend_port                   = 8090
  frontend_ip_configuration_name = "TransformServiceLbConf"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.loadbalancer_transform_service_backend.id}"
  probe_id                       = "${azurerm_lb_probe.loadbalancer_libreoffice_probe.id}"
  load_distribution              = "SourceIPProtocol"
}

resource "azurerm_lb_rule" "PDFRendererEndPointListener" {
  resource_group_name            = "${azurerm_resource_group.deployment_rg.name}"
  loadbalancer_id                = "${azurerm_lb.transform-service-loadbalancer.id}"
  name                           = "PDFRendererEndPointListener"
  protocol                       = "Tcp"
  frontend_port                  = 8091
  backend_port                   = 8091
  frontend_ip_configuration_name = "TransformServiceLbConf"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.loadbalancer_transform_service_backend.id}"
  probe_id                       = "${azurerm_lb_probe.loadbalancer_pdf_renderer_probe.id}"
  load_distribution              = "SourceIPProtocol"
}

resource "azurerm_lb_rule" "ImageMagickEndPointListener" {
  resource_group_name            = "${azurerm_resource_group.deployment_rg.name}"
  loadbalancer_id                = "${azurerm_lb.transform-service-loadbalancer.id}"
  name                           = "ImageMagickEndPointListener"
  protocol                       = "Tcp"
  frontend_port                  = 8092
  backend_port                   = 8092
  frontend_ip_configuration_name = "TransformServiceLbConf"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.loadbalancer_transform_service_backend.id}"
  probe_id                       = "${azurerm_lb_probe.loadbalancer_imagemagick_probe.id}"
  load_distribution              = "SourceIPProtocol"
}

resource "azurerm_lb_rule" "TikaEndPointListener" {
  resource_group_name            = "${azurerm_resource_group.deployment_rg.name}"
  loadbalancer_id                = "${azurerm_lb.transform-service-loadbalancer.id}"
  name                           = "TikaEndPointListener"
  protocol                       = "Tcp"
  frontend_port                  = 8093
  backend_port                   = 8093
  frontend_ip_configuration_name = "TransformServiceLbConf"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.loadbalancer_transform_service_backend.id}"
  probe_id                       = "${azurerm_lb_probe.loadbalancer_tika_probe.id}"
  load_distribution              = "SourceIPProtocol"
}

resource "azurerm_lb_rule" "SharedFileStoreEndPointListener" {
  resource_group_name            = "${azurerm_resource_group.deployment_rg.name}"
  loadbalancer_id                = "${azurerm_lb.transform-service-loadbalancer.id}"
  name                           = "SharedFileStoreEndPointListener"
  protocol                       = "Tcp"
  frontend_port                  = 8094
  backend_port                   = 8094
  frontend_ip_configuration_name = "TransformServiceLbConf"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.loadbalancer_transform_service_backend.id}"
  probe_id                       = "${azurerm_lb_probe.loadbalancer_shared_file_store_probe.id}"
  load_distribution              = "SourceIPProtocol"
}

####### AZURE STORAGE SHARE (AZURE FILES) #########
resource "azurerm_storage_account" "contentstore" {
  name                     = "content${random_id.randomId.hex}"
  resource_group_name      = "${azurerm_resource_group.deployment_rg.name}"
  location                 = "${var.LOCATION}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "contentstores" {
  name = "alf-contentstores"

  resource_group_name  = "${azurerm_resource_group.deployment_rg.name}"
  storage_account_name = "${azurerm_storage_account.contentstore.name}"

  quota = 50
}

data "azurerm_storage_account" "contentstores-data" {
  name                = "content${random_id.randomId.hex}"
  resource_group_name = "${azurerm_resource_group.deployment_rg.name}"
  depends_on = [ "azurerm_storage_share.contentstores" ]
}

resource "azurerm_storage_share" "shared-file-store" {
  name = "shared-file-store"

  resource_group_name  = "${azurerm_resource_group.deployment_rg.name}"
  storage_account_name = "${azurerm_storage_account.contentstore.name}"

  quota = 5
}

########### VIRTUAL MACHINE DEFINITIONS ##########


###### BASTION #########

# Create network interface - bastion
resource "azurerm_network_interface" "bastionnic" {
    name                      = "bastionNIC"
    location                  = "${var.LOCATION}"
    resource_group_name       = "${azurerm_resource_group.deployment_rg.name}"
    network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"

    ip_configuration {
        name                          = "NicConfBastion1"
        subnet_id                     = "${azurerm_subnet.backend_subnet.id}"
        private_ip_address_allocation = "Static"
        public_ip_address_id          = "${azurerm_public_ip.bastion_public_ip.id}"
        private_ip_address            = "${var.bastion_private_ip}"
    }

    tags {
        environment = "Alfresco 6.1 Demo"
    }
}

# Create virtual machine - bastion
resource "azurerm_virtual_machine" "bastionvm" {
    name                  = "bastion-vm"
    location              = "${var.LOCATION}"
    resource_group_name   = "${azurerm_resource_group.deployment_rg.name}"
    network_interface_ids = ["${azurerm_network_interface.bastionnic.id}"]
    vm_size               = "Standard_B1s"

    storage_os_disk {
        name              = "BastionDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
       publisher = "OpenLogic"
       offer     = "CentOS"
       sku       = "7.6"
       version   = "7.6.20181219"
    }

    os_profile {
        computer_name  = "bastion-vm"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "${file("${var.SSH_PUBLIC_KEY_FILE}")}"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags {
        environment = "Alfresco 6.1 Demo"
    }

    provisioner "ansible" {
      plays {
        playbook = {
           file_path = "./ansible-configure-vm/bastion-vm.yaml"
           roles_path = [
             "./ansible-configure-vm/roles"
           ]
        }
        extra_vars = {
              activemq_0_host = "${lookup(var.activemq_private_ip, "activemq_0")}",
              activemq_1_host = "${lookup(var.activemq_private_ip, "activemq_1")}",
              frontend_0_host = "${lookup(var.frontend_private_ip, "frontend_0")}",
              frontend_1_host = "${lookup(var.frontend_private_ip, "frontend_1")}",
              insight_0_host = "${lookup(var.insight_private_ip, "insight_0")}",
              insight_1_host = "${lookup(var.insight_private_ip, "insight_1")}",
              transformation_0_host = "${lookup(var.transformation_private_ip, "transformation_0")}",
              transformation_1_host = "${lookup(var.transformation_private_ip, "transformation_1")}",
              db_host = "${var.db_private_ip}"
        }
        hosts = ["localhost"]
        become = "true"
     }
     remote {
       skip_install = "false"
     }
   }

    connection {
        user = "azureuser"
        private_key = "${file("${var.SSH_PRIVATE_KEY_FILE}")}"
    }
}

###### ACTIVEMQ NODES #########

resource "azurerm_availability_set" "activemq_avset" {
  name                         = "activemq_avset"
  location                     = "${var.LOCATION}"
  resource_group_name          = "${azurerm_resource_group.deployment_rg.name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

# Create network interface - activemq
resource "azurerm_network_interface" "activemq_nic" {
    name                      = "activemq_nic${count.index}"
    location                  = "${var.LOCATION}"
    resource_group_name       = "${azurerm_resource_group.deployment_rg.name}"
    network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"
    count                     = 2

    ip_configuration {
        name                          = "ipconfig${count.index}"
        subnet_id                     = "${azurerm_subnet.backend_subnet.id}"
        private_ip_address_allocation = "Static"
        private_ip_address = "${lookup(var.activemq_private_ip, "activemq_${count.index}")}"
    }

    tags {
        environment = "Alfresco 6.1 Demo"
    }
}

# Create virtual machines - activemq_nodes
resource "azurerm_virtual_machine" "activemq_vm" {
    name                  = "activemq-${count.index}-vm"
    location              = "${var.LOCATION}"
    resource_group_name   = "${azurerm_resource_group.deployment_rg.name}"
    network_interface_ids = ["${element(azurerm_network_interface.activemq_nic.*.id, count.index)}"]
    availability_set_id   = "${azurerm_availability_set.activemq_avset.id}"
    vm_size               = "Standard_B1s"
    count                 = 2

    depends_on = [
       "azurerm_public_ip.bastion_public_ip",
       "azurerm_virtual_machine.bastionvm"
    ]

    storage_os_disk {
        name              = "activemq-${count.index}-Disk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
    	id = "/subscriptions/${var.SUBSCRIPTION_ID}/resourceGroups/${var.RESOURCE_GROUP_IMAGES}/providers/Microsoft.Compute/images/ActivemqImage"
    }

    os_profile {
        computer_name  = "activemq-${count.index}-vm"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "${file("${var.SSH_PUBLIC_KEY_FILE}")}"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags {
        environment = "Alfresco 6.1 Demo"
    }

    connection {
        user = "azureuser"
        private_key = "${file("${var.SSH_PRIVATE_KEY_FILE}")}"
        bastion_host = "${data.azurerm_public_ip.bastion_public_ip.ip_address}"
        bastion_user = "azureuser"
        bastion_private_key = "${file("${var.SSH_PRIVATE_KEY_FILE}")}"
    }

    provisioner "ansible" {
      plays {
        playbook = {
           file_path = "./ansible-configure-vm/activemq-vm.yaml"
           roles_path = [
             "./ansible-configure-vm/roles"
           ]
        }
        extra_vars = {
              activemq_node_peer = "activemq-${(count.index + 1) % 2}-vm"
        }
        hosts = ["localhost"]
        become = "true"
     }
     remote {
       skip_install = "true"
     }
   }
}

#### DB SERVER #####

# Create network interface - db
resource "azurerm_network_interface" "dbnic" {
    name                      = "dbNIC"
    location                  = "${var.LOCATION}"
    resource_group_name       = "${azurerm_resource_group.deployment_rg.name}"
    network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"

    ip_configuration {
        name                          = "NicConfDB"
        subnet_id                     = "${azurerm_subnet.backend_subnet.id}"
        private_ip_address_allocation = "Static"
        private_ip_address = "${var.db_private_ip}"
    }

    tags {
        environment = "Alfresco 6.1 Demo"
    }
}

# Create virtual machine - db
resource "azurerm_virtual_machine" "dbvm" {
    name                  = "db-vm"
    location              = "${var.LOCATION}"
    resource_group_name   = "${azurerm_resource_group.deployment_rg.name}"
    network_interface_ids = ["${azurerm_network_interface.dbnic.id}"]
    vm_size               = "Standard_B2s"

    depends_on = [
                 "azurerm_virtual_machine.bastionvm",
                 "azurerm_public_ip.bastion_public_ip"
                ]

    storage_os_disk {
        name              = "DB_Disk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
    	id = "/subscriptions/${var.SUBSCRIPTION_ID}/resourceGroups/${var.RESOURCE_GROUP_IMAGES}/providers/Microsoft.Compute/images/DBImage"
    }

    os_profile {
        computer_name  = "db-vm"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "${file("${var.SSH_PUBLIC_KEY_FILE}")}"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags {
        environment = "Alfresco 6.1 Demo"
    }

    connection {
        user = "azureuser"
        private_key = "${file("${var.SSH_PRIVATE_KEY_FILE}")}"
        bastion_host = "${data.azurerm_public_ip.bastion_public_ip.ip_address}"
        bastion_user = "azureuser"
        bastion_private_key = "${file("${var.SSH_PRIVATE_KEY_FILE}")}"
    }

    provisioner "ansible" {
      plays {
        playbook = {
           file_path = "./ansible-configure-vm/db-vm.yaml"
           roles_path = [
             "./ansible-configure-vm/roles"
           ]
        }
        hosts = ["localhost"]
        become = "true"
     }
     remote {
       skip_install = "true"
     }
   }
}

###### FRONTENDS #########

resource "azurerm_availability_set" "frontend_avset" {
  name                         = "frontend_avset"
  location                     = "${var.LOCATION}"
  resource_group_name          = "${azurerm_resource_group.deployment_rg.name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

# Create network interface - frontend
resource "azurerm_network_interface" "frontend_nic" {
    name                      = "frontend_nic${count.index}"
    location                  = "${var.LOCATION}"
    resource_group_name       = "${azurerm_resource_group.deployment_rg.name}"
    network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"
    count                     = 2

    ip_configuration {
        name                          = "frontend_ipconfig"
        subnet_id                     = "${azurerm_subnet.backend_subnet.id}"
        private_ip_address_allocation = "Static"
        private_ip_address = "${lookup(var.frontend_private_ip, "frontend_${count.index}")}"
    }

    tags {
        environment = "Alfresco 6.1 Demo"
    }
}

# Create virtual machines - frontends
resource "azurerm_virtual_machine" "frontend_vm" {
    name                  = "frontend-${count.index}-vm"
    location              = "${var.LOCATION}"
    resource_group_name   = "${azurerm_resource_group.deployment_rg.name}"
    network_interface_ids = ["${azurerm_network_interface.frontend_nic.*.id[count.index]}"]
    availability_set_id   = "${azurerm_availability_set.frontend_avset.id}"
    vm_size               = "Standard_B2s"
    count                 = 2

    depends_on = [
       "azurerm_public_ip.bastion_public_ip",
       "azurerm_virtual_machine.bastionvm",
       "azurerm_virtual_machine.dbvm",
       "azurerm_virtual_machine.activemq_vm",
       "azurerm_network_interface.frontend_nic"
    ]

    storage_os_disk {
        name              = "frontend-${count.index}-Disk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
    	id = "/subscriptions/${var.SUBSCRIPTION_ID}/resourceGroups/${var.RESOURCE_GROUP_IMAGES}/providers/Microsoft.Compute/images/AlfrescoFrontendImage"
    }

    os_profile {
        computer_name  = "frontend-${count.index}-vm"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "${file("${var.SSH_PUBLIC_KEY_FILE}")}"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags {
        environment = "Alfresco 6.1 Demo"
    }

    connection {
        user = "azureuser"
        private_key = "${file("${var.SSH_PRIVATE_KEY_FILE}")}"
        bastion_host = "${data.azurerm_public_ip.bastion_public_ip.ip_address}"
        bastion_user = "azureuser"
        bastion_private_key = "${file("${var.SSH_PRIVATE_KEY_FILE}")}"
    }

    provisioner "remote-exec" {
        inline = [
          "sudo touch /etc/smb-credentials",
          "sudo chmod 440 /etc/smb-credentials",
          "sudo sh -c \"echo \"username=${azurerm_storage_account.contentstore.name}\" > /etc/smb-credentials\"",
          "sudo sh -c \"echo \"password=${data.azurerm_storage_account.contentstores-data.primary_access_key}\" >> /etc/smb-credentials\""
        ]
    }

    provisioner "ansible" {
      plays {
        playbook = {
           file_path = "./ansible-configure-vm/frontend-vm.yaml"
           roles_path = [
             "./ansible-configure-vm/roles"
           ]
        }
        extra_vars = {
              solr_host = "${var.search_services_lb_private_ip}",
              transform_service_host = "${var.transform_service_lb_private_ip}",
              alfresco_host = "${local.alfresco_fqdn}",
              share_host = "${local.alfresco_fqdn}"
        }
        hosts = ["localhost"]
        become = "true"
     }
     remote {
       skip_install = "true"
     }
   }
}

resource "azurerm_network_interface_backend_address_pool_association" "frontend_lb_association" {
    network_interface_id    = "${element(azurerm_network_interface.frontend_nic.*.id,count.index)}"
    ip_configuration_name   = "frontend_ipconfig"
    backend_address_pool_id = "${azurerm_lb_backend_address_pool.loadbalancer_internal_repository_backend.id}"
    count=2

    depends_on = [
             "azurerm_network_interface.frontend_nic",
             "azurerm_lb_backend_address_pool.loadbalancer_internal_repository_backend"
           ]
}

###### INSIGHT ENGINE - NODES #########

resource "azurerm_availability_set" "insight_avset" {
  name                         = "insight_avset"
  location                     = "${var.LOCATION}"
  resource_group_name          = "${azurerm_resource_group.deployment_rg.name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

# Create network interface - insight
resource "azurerm_network_interface" "insight_nic" {
    name                      = "insight_nic${count.index}"
    location                  = "${var.LOCATION}"
    resource_group_name       = "${azurerm_resource_group.deployment_rg.name}"
    network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"
    count                     = 2

    ip_configuration {
        name                          = "insight_ipconfig"
        subnet_id                     = "${azurerm_subnet.backend_subnet.id}"
        private_ip_address_allocation = "Static"
        private_ip_address = "${lookup(var.insight_private_ip, "insight_${count.index}")}"
    }

    tags {
        environment = "Alfresco 6.1 Demo"
    }
}

# Create virtual machines - Insight Engine
resource "azurerm_virtual_machine" "insight_vm" {
    name                  = "insight-${count.index}-vm"
    location              = "${var.LOCATION}"
    resource_group_name   = "${azurerm_resource_group.deployment_rg.name}"
    network_interface_ids = ["${element(azurerm_network_interface.insight_nic.*.id, count.index)}"]
    availability_set_id   = "${azurerm_availability_set.insight_avset.id}"
    vm_size               = "Standard_B2s"
    count                 = 2

    depends_on = [
       "azurerm_public_ip.bastion_public_ip",
       "azurerm_virtual_machine.bastionvm",
       "azurerm_virtual_machine.dbvm"
    ]

    storage_os_disk {
        name              = "insight-${count.index}-Disk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
    	id = "/subscriptions/${var.SUBSCRIPTION_ID}/resourceGroups/${var.RESOURCE_GROUP_IMAGES}/providers/Microsoft.Compute/images/InsightEngineImage"
    }

    os_profile {
        computer_name  = "insight-${count.index}-vm"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "${file("${var.SSH_PUBLIC_KEY_FILE}")}"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags {
        environment = "Alfresco 6.1 Demo"
    }

    connection {
        user = "azureuser"
        private_key = "${file("${var.SSH_PRIVATE_KEY_FILE}")}"
        bastion_host = "${data.azurerm_public_ip.bastion_public_ip.ip_address}"
        bastion_user = "azureuser"
        bastion_private_key = "${file("${var.SSH_PRIVATE_KEY_FILE}")}"
    }

    provisioner "ansible" {
      plays {
        playbook = {
           file_path = "./ansible-configure-vm/insight-engine-vm.yaml"
           roles_path = [
             "./ansible-configure-vm/roles"
           ]
        }
        hosts = ["localhost"]
        become = "true"
        extra_vars = {
              alfresco_repo_internal_lb = "${var.internal_repository_lb_private_ip}"
        }
      }
     remote {
       skip_install = "true"
     }
   }
}

resource "azurerm_network_interface_backend_address_pool_association" "insight_lb_association" {
  network_interface_id    = "${element(azurerm_network_interface.insight_nic.*.id,count.index)}"
  ip_configuration_name   = "insight_ipconfig"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.loadbalancer_search_services_backend.id}"
  count=2

  depends_on = [
             "azurerm_network_interface.insight_nic",
             "azurerm_lb_backend_address_pool.loadbalancer_search_services_backend"
           ]

}

###### TRANSFORMATION SERVICE NODES #########

resource "azurerm_availability_set" "transformation_avset" {
  name                         = "transformation_avset"
  location                     = "${var.LOCATION}"
  resource_group_name          = "${azurerm_resource_group.deployment_rg.name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

# Create network interface - transformation
resource "azurerm_network_interface" "transformation_nic" {
    name                      = "transformation_nic${count.index}"
    location                  = "${var.LOCATION}"
    resource_group_name       = "${azurerm_resource_group.deployment_rg.name}"
    network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"
    count                     = 2

    ip_configuration {
        name                          = "transformation_ipconfig"
        subnet_id                     = "${azurerm_subnet.backend_subnet.id}"
        private_ip_address_allocation = "Static"
        private_ip_address = "${lookup(var.transformation_private_ip, "transformation_${count.index}")}"
    }

    tags {
        environment = "Alfresco 6.1 Demo"
    }
}

# Create virtual machines - transformation_nodes
resource "azurerm_virtual_machine" "transformation_vm" {
    name                  = "transformation-${count.index}-vm"
    location              = "${var.LOCATION}"
    resource_group_name   = "${azurerm_resource_group.deployment_rg.name}"
    network_interface_ids = ["${element(azurerm_network_interface.transformation_nic.*.id, count.index)}"]
    availability_set_id   = "${azurerm_availability_set.transformation_avset.id}"
    vm_size               = "Standard_B2s"
    count                 = 2

    depends_on = [
       "azurerm_public_ip.bastion_public_ip",
       "azurerm_virtual_machine.bastionvm"
    ]

    storage_os_disk {
        name              = "transformation-${count.index}-Disk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
    	id = "/subscriptions/${var.SUBSCRIPTION_ID}/resourceGroups/${var.RESOURCE_GROUP_IMAGES}/providers/Microsoft.Compute/images/TransformationServiceImage"
    }

    os_profile {
        computer_name  = "transformation-${count.index}-vm"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "${file("${var.SSH_PUBLIC_KEY_FILE}")}"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags {
        environment = "Alfresco 6.1 Demo"
    }

    connection {
        user = "azureuser"
        private_key = "${file("${var.SSH_PRIVATE_KEY_FILE}")}"
        bastion_host = "${data.azurerm_public_ip.bastion_public_ip.ip_address}"
        bastion_user = "azureuser"
        bastion_private_key = "${file("${var.SSH_PRIVATE_KEY_FILE}")}"
    }

    provisioner "remote-exec" {
        inline = [
          "sudo touch /etc/smb-credentials",
          "sudo chmod 440 /etc/smb-credentials",
          "sudo sh -c \"echo \"username=${azurerm_storage_account.contentstore.name}\" > /etc/smb-credentials\"",
          "sudo sh -c \"echo \"password=${data.azurerm_storage_account.contentstores-data.primary_access_key}\" >> /etc/smb-credentials\""
        ]
    }

    provisioner "ansible" {
      plays {
        playbook = {
           file_path = "./ansible-configure-vm/transform-service-vm.yaml"
           roles_path = [
             "./ansible-configure-vm/roles"
           ]
        }
        hosts = ["localhost"]
        become = "true"
     }
     remote {
       skip_install = "true"
     }
   }
}

resource "azurerm_network_interface_backend_address_pool_association" "transformation_lb_association" {
  network_interface_id    = "${element(azurerm_network_interface.transformation_nic.*.id,count.index)}"
  ip_configuration_name   = "transformation_ipconfig"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.loadbalancer_transform_service_backend.id}"
  count=2

  depends_on = [
             "azurerm_network_interface.transformation_nic",
             "azurerm_lb_backend_address_pool.loadbalancer_transform_service_backend"
           ]
}

####### Application Gateway #########

# Create LB public IP
resource "azurerm_public_ip" "app_gateway_public_ip" {
    name                         = "app_gateway_Ip"
    location                     = "${var.LOCATION}"
    resource_group_name          = "${azurerm_resource_group.deployment_rg.name}"
    allocation_method            = "Dynamic"
    domain_name_label            = "${local.alfresco_domain_label}"
    sku = "Basic"

    tags {
        environment = "Alfresco 6.1 Demo"
    }
}

resource "azurerm_subnet" "app_gateway_subnet" {
  name                 = "app-gateway-subnet"
  resource_group_name  = "${azurerm_resource_group.deployment_rg.name}"
  virtual_network_name = "${azurerm_virtual_network.virtual-network.name}"
  address_prefix       = "10.0.0.0/24"
}

# locals block for app-gateway variables
locals {
  backend_address_pool_name      = "${azurerm_virtual_network.virtual-network.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.virtual-network.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.virtual-network.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.virtual-network.name}-http"
  listener_name                  = "${azurerm_virtual_network.virtual-network.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.virtual-network.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.virtual-network.name}-rdrcfg"
  url_path_map_name              = "${azurerm_virtual_network.virtual-network.name}-urlpm"
  path_rule_name                 = "${azurerm_virtual_network.virtual-network.name}-prn"
  probe_name                     = "${azurerm_virtual_network.virtual-network.name}-prb"

  http_setting_name_zp           = "${azurerm_virtual_network.virtual-network.name}-http-zp"
  path_rule_name_zp              = "${azurerm_virtual_network.virtual-network.name}-prn-zp"
  probe_name_zp                  = "${azurerm_virtual_network.virtual-network.name}-prb-zp"
}

resource "azurerm_application_gateway" "app_gateway" {
  name                = "appgateway"
  resource_group_name = "${azurerm_resource_group.deployment_rg.name}"
  location            = "${var.LOCATION}"

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = "${azurerm_subnet.app_gateway_subnet.id}"
  }

  frontend_port {
    name = "${local.frontend_port_name}"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "${local.frontend_ip_configuration_name}"
    public_ip_address_id = "${azurerm_public_ip.app_gateway_public_ip.id}"
  }

  backend_address_pool {
    name = "${local.backend_address_pool_name}"
    ip_addresses = ["${azurerm_network_interface.frontend_nic.*.private_ip_address}"]
  }

  ##### Alfresco and Share internal ports ######
  backend_http_settings {
    name                  = "${local.http_setting_name}"
    cookie_based_affinity = "Enabled"
    port                  = 8080
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = "${local.probe_name}"
  }

  ##### Zeppelin internal port ######
  backend_http_settings {
    name                  = "${local.http_setting_name_zp}"
    cookie_based_affinity = "Enabled"
    port                  = 9090
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = "${local.probe_name_zp}"
  }

  http_listener {
    name                           = "${local.listener_name}"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}"
    frontend_port_name             = "${local.frontend_port_name}"
    protocol                       = "Http"
  }

  url_path_map{
    name = "${local.url_path_map_name}"
    default_backend_address_pool_name = "${local.backend_address_pool_name}"
    default_backend_http_settings_name = "${local.http_setting_name}"

    path_rule = {
       name = "${local.path_rule_name}"
       backend_address_pool_name = "${local.backend_address_pool_name}"
       backend_http_settings_name = "${local.http_setting_name}"
       paths = ["/alfresco","/share","/alfresco/*","/share/*"]
    }

    path_rule = {
       name = "${local.path_rule_name_zp}"
       backend_address_pool_name = "${local.backend_address_pool_name}"
       backend_http_settings_name = "${local.http_setting_name_zp}"
       paths = ["/zeppelin","/zeppelin/*"]
    }
  }

  request_routing_rule {
    name                        = "${local.request_routing_rule_name}"
    rule_type                   = "PathBasedRouting"
    http_listener_name          = "${local.listener_name}"
    backend_address_pool_name   = "${local.backend_address_pool_name}"
    backend_http_settings_name  = "${local.http_setting_name}"
    url_path_map_name           = "${local.url_path_map_name}"
  }

  probe {
    interval = 10
    host = "${local.alfresco_fqdn}"
    name = "${local.probe_name}"
    protocol = "Http"
    path = "/alfresco/"
    timeout = "8"
    unhealthy_threshold = "10"
    match {
       status_code = [ "200" ]
       body = "Alfresco Administration Console"
    }
  }

  probe {
    interval = 10
    host = "${local.alfresco_fqdn}"
    name = "${local.probe_name_zp}"
    protocol = "Http"
    path = "/zeppelin/"
    timeout = "5"
    unhealthy_threshold = "5"
    match {
       status_code = [ "200" ]
       body = "Licensed under the Apache License"
    }
   }

}

########### OUTPUTS ##########
output "bastion_ip" {
  value = "${data.azurerm_public_ip.bastion_public_ip.ip_address}"
}

output "app_gateway_ip" {
  value = "${azurerm_public_ip.app_gateway_public_ip.ip_address}"
}

output "dns_name" {
  value = "${local.alfresco_fqdn}"
}
