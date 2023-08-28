variable "public_subnets" {
    type = list
    description = "list of Public subnets"
}

variable "private_subnets" {
    type = list
    description = "list of private subnets"
}

variable "db_subnets" {
    type = list
    description = "list of db subnets"
}

variable "azs" {
    type = list
    description = "list of avaialbility zones"
}

variable "vpc_cidr" {
    type = string
    description = "vpc main cidr"
}