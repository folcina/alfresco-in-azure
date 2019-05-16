variable "CLIENT_ID" {}
variable "CLIENT_SECRET" {}
variable "SUBSCRIPTION_ID" {}
variable "TENANT_ID" {}

variable "DOMAIN_NAME_LABEL" {}
variable "LOCATION" {}
variable "RESOURCE_GROUP_IMAGES" {}
variable "RESOURCE_GROUP_DEPLOYMENT" {}

variable "azure_cloudapp_dns" {
  type = "string"
  default = "cloudapp.azure.com"
}

variable "bastion_private_ip" {
  type = "string"
  default = "10.0.1.4"
}

variable "activemq_private_ip" {
  default = {
     activemq_0 = "10.0.1.5",
     activemq_1 = "10.0.1.6"
  }
}

variable "frontend_private_ip" {
  default = {
     frontend_0 = "10.0.1.7",
     frontend_1 = "10.0.1.8"
  }
}

variable "insight_private_ip" {
  default = {
     insight_0 = "10.0.1.9",
     insight_1 = "10.0.1.10"
  }
}

variable "transformation_private_ip" {
  default = {
     transformation_0 = "10.0.1.11",
     transformation_1 = "10.0.1.12"
  }
}

variable "search_services_lb_private_ip" {
  type = "string"
  default = "10.0.1.13"
}

variable "internal_repository_lb_private_ip" {
  type = "string"
  default = "10.0.1.14"
}

variable "shared_file_store_lb_private_ip" {
  type = "string"
  default = "10.0.1.15"
}

variable "db_private_ip" {
  type = "string"
  default = "10.0.1.16"
}
