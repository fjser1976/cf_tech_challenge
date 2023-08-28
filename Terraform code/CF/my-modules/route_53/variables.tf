variable "domain_name" {
    type = string
    description = "public domain name to setup with route 53"
}

variable "sub_domain_name" {
    type = string
    description = "psub domain name to setup with route 53"
}

variable "ttl" {
    type = string
    description = "ttl for certificate"
}

variable "records" {
    type = list
}