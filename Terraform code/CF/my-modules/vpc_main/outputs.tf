output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "vpc_az_list" {
  description = "List of AZs supported in this VPC"
  value       = var.azs
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value = aws_subnet.public_nets.*.id
}

output "public_subnets_cidr_blocks" {
  description = "List of IPv4 CIDR blocks of public subnets"
  value = aws_subnet.public_nets.*.cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value = aws_subnet.private_nets.*.id
}

output "private_subnets_cidr_blocks" {
  description = "List of IPv4 CIDR blocks of private subnets"
  value = aws_subnet.private_nets.*.cidr_block
}

output "db_subnets" {
  description = "List of IDs of db subnets"
  value = aws_subnet.db_nets.*.id
}

output "db_subnets_cidr_blocks" {
  description = "List of IPv4 CIDR blocks of db subnets"
  value = aws_subnet.db_nets.*.cidr_block
}
