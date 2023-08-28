variable "ad_full_name" {
  description = "Full name of active directory domain"
  type = string
}

variable "ad_short_name" {
  description = "Short name of active directory domain"
  type = string
}

variable "ad_default_password" {
  description = "Default Password for New AD"
  type = string
}

variable "ad_description" {
  description = "Description of AD Domain"
  type = string
}

variable "ad_type" {
  description = "type of directory"
  type = string
}

variable "ad_edition" {
  description = "MS AD edition"
  type = string
}

variable "vpc_id" {
  description = "VPC to put the AD in"
  type = string
}

variable "ad_subnet_az1" {
  description = "First AZ subnet for resolver endpoints"
  type = string
}

variable "ad_subnet_az2" {
  description = "Second AZ subnet for resolver endpoints"
  type = string
}


