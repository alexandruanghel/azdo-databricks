variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group in which the resources should exist."
}

variable "azure_location" {
  type        = string
  description = "(Optional) Azure location in which the resources should exist. If not set, it will use the location of the Resource Group."
  default     = null
}

variable "virtual_network_name" {
  type        = string
  description = "(Optional) The name of the Virtual Network where the Databricks clusters should be created. Default is workers-vnet."
  default     = "workers-vnet"
}

variable "virtual_network_cidr" {
  type        = string
  description = "(Optional) CIDR range for the Virtual Network (must be at least /24). Default is 10.179.0.0/16"
  default     = "10.179.0.0/16"

  validation {
    condition     = tonumber(regex("/(\\d+)", var.virtual_network_cidr)[0]) <= 24
    error_message = "The CIDR prefix for the Databricks Virtual Network must be at least /24."
  }
}


variable "private_subnet_name" {
  type        = string
  description = "(Optional) The name of the Private Subnet within the Virtual Network. Default is private-subnet."
  default     = "private-subnet"
}

variable "private_subnet_cidr" {
  type        = string
  description = "(Optional) CIDR range for the Private Subnet (must be at least /26). Default is 10.179.0.0/18."
  default     = "10.179.0.0/18"

  validation {
    condition     = tonumber(regex("/(\\d+)", var.private_subnet_cidr)[0]) <= 26
    error_message = "The CIDR prefix for the Databricks Private Subnet must be at least /26."
  }
}

variable "public_subnet_name" {
  type        = string
  description = "(Optional) The name of the Public Subnet within the Virtual Network. Default is public-subnet."
  default     = "public-subnet"
}

variable "public_subnet_cidr" {
  type        = string
  description = "(Optional) CIDR range for the Public Subnet (must be at least /26). Default is 10.179.64.0/18."
  default     = "10.179.64.0/18"

  validation {
    condition     = tonumber(regex("/(\\d+)", var.public_subnet_cidr)[0]) <= 26
    error_message = "The CIDR prefix for the Databricks Public Subnet must be at least /26."
  }
}

variable "network_security_group_name" {
  type        = string
  description = "(Optional) The name of the Databricks Network Security Group attached to the subnets. Default is databricks-nsg."
  default     = "databricks-nsg"
}

variable "service_endpoints" {
  type        = list(string)
  description = "(Optional) A list of service endpoints to associate with the public subnet."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to the resources."
  default     = {}
}
