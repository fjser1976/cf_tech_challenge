variable "region_name" {
    type        = string
    description = "region to build in"
}

variable "vpc_cidr" {
    type        = string
    description = "main cidr for primary vpc"
}

variable "public_nets" {
    type        = list
    description = "list of public subnets to create from main vpc cidr"
}

variable "private_nets" {
    type        = list
    description = "list of private subnets to create from main vpc cidr"
}

variable "db_nets" {
    type        = list
    description = "list of db subnets to create from main vpc cidr"
}

variable "avail_zones" {
    type        = list
    description = "list of availability zones to create resources in"
}

variable "win_image" {
    type        = string
    description = "Windows Image to use"
}

variable "linux_image" {
    type        = string
    description = "linux Image to use"
}

variable "win_type" {
    type        = string
    description = "Windows ec2 type"
}

variable "linux_type" {
    type        = string
    description = "linux ec2 type"
}

variable "win_hostnames" {
    type        = list
    description = "Windows hostnames"
}

variable "linux_hostnames" {
    type        = list
    description = "linux hostnames"
}

variable "win_vol_size" {
    type        = string
    description = "Windows vol size"
}

variable "linux_vol_size" {
    type        = string
    description = "linux vol size"
}

variable "vol_type" {
    type        = string
    description = "type of volume to use"
}

variable "domain_name" {
    type        = string
    description = "main domain name"
}

variable "sub_domain_name" {
    type        = string
    description = "sub domain name"
}

variable "ttl" {
    type        = string
    description = "ttl time for cert"
}

variable "records" {
    type        = list
    description = "records list"
}