resource "aws_vpc" "this" {
  enable_dns_hostnames = true

  tags = {
    Name = "main vpc"
  }

  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "public_nets" {
    count = length(var.azs)
    vpc_id = aws_vpc.this.id
    cidr_block = var.public_subnets[count.index]
    availability_zone = var.azs[count.index]
    map_public_ip_on_launch = "true"
    tags = {
        Name = "Public Subnet ${count.index +1}"
    }
}

resource "aws_subnet" "private_nets" {
    count = length(var.azs)
    vpc_id = aws_vpc.this.id
    cidr_block = var.private_subnets[count.index]
    availability_zone = var.azs[count.index]

    tags = {
        Name = "Private Subnet ${count.index +1}"
    }
}

resource "aws_subnet" "db_nets" {
    count = length(var.azs)
    vpc_id = aws_vpc.this.id
    cidr_block = var.db_subnets[count.index]
    availability_zone = var.azs[count.index]

    tags = {
        Name = "DB Subnet ${count.index +1}"
    }
}

resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.this.id
    tags = {
        Name = "Project VPC IG"
    }
}

resource "aws_route_table" "inbound_rt_table" {
    vpc_id = aws_vpc.this.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    }

    tags = {
        Name = "Inbound Public Route Table"
    }
}

resource "aws_route_table_association" "public_association" {
     count = length(var.public_subnets)
     subnet_id = element(aws_subnet.public_nets.*.id, count.index)
     #subnet_id = aws_subnet.public_nets.*.id[count.index]
     route_table_id = aws_route_table.inbound_rt_table.id
}

