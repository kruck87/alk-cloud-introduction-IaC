variable "project_id" {
    description = "ID projektu"
    type = string
    default = "terraform-cloud-introduction"
}

variable "zone" {
  description = "Zone"
  type = string
  default = "europe-west1-b"
}

variable "region" {
  description = "Region"
  type = string
  default = "europe-west1"
}

variable "network" {
    description = "VPC Network"
    type = string
    default = "terraform-network-001"
  
}

variable "subnet" {
    description = "Subnet name"
    type = string
    default = "terraform-subnet-001"
  
}

#variable "compute_engine_default_service_account_name" {
#  description = "Nazwa domyślnego konta serwisowego dla compute engine"
#  type = string
#  default = "Compute Engine default service account"
#  
#}

#variable "compute_engine_default_service_account_id" {
#  description = "Id domyślnego konta serwisowego dla compute engine"
#  type = string
#  default = "106004746516261247308"
#  
#}