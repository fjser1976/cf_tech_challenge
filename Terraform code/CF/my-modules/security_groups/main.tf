#Create Default Security Groups for Windows EC2 instances

#postgres sec group - allow only 5432 inbound to DB servers, and ssh from bastian
resource "aws_security_group" "secgrp_postgressql" {
    name = "secgrp_postgressql"
    description = "Security group for post gres servers"
    vpc_id = var.vpc_id
    
    ingress {
        from_port = 5432
        to_port   = 5432
        protocol  = "tcp"
        security_groups = [aws_security_group.secgrp_web_servers.id]
        description = "Allow postgres inbound"
    }

    ingress {
        from_port = 5432
        to_port   = 5432
        protocol  = "udp"
        security_groups = [aws_security_group.secgrp_web_servers.id]
        description = "Allow postgres inbounc"
    }

    ingress {
        from_port = 0
        to_port   = 0
        protocol  = "-1"
        self = true
        description = "Allow communication between DB servers for replication in case we set that up"
    }

    ingress {
        from_port = 22
        to_port   = 22
        protocol  = "tcp"
        security_groups = [aws_security_group.secgrp_bastian_servers.id]
        description = "Allow SSH from bastian"
    }
}   

#webservers - allows 443 and 80 in from ALB, ssh from bastian
resource "aws_security_group" "secgrp_web_servers" {
    name = "secgrp_webservers"
    description = "Security group for web servers"
    vpc_id = var.vpc_id
    
    ingress {
        from_port = 443
        to_port   = 443
        protocol  = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow HTTPS inbound"
    }
    ingress {
        from_port = 80
        to_port   = 80
        protocol  = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow HTTP inbound"
    }
    ingress {
        from_port = 22
        to_port   = 22
        protocol  = "tcp"
        security_groups = [aws_security_group.secgrp_bastian_servers.id]
        description = "Allow SSH from bastian"
    }
}   

#Load Balancer - allow 443 in and 443/80 out to web servers
resource "aws_security_group" "secgrp_alb" {
    name = "secgrp_albservers"
    description = "Security group for application load balancer"
    vpc_id = var.vpc_id
    
    ingress {
        from_port = 443
        to_port   = 443
        protocol  = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow HTTPS inbound"
    }

    egress {
        from_port = 80
        to_port   = 80
        protocol  = "tcp"
        security_groups = [aws_security_group.secgrp_web_servers.id]
        description = "Allow HTTP outbound"
    }

    egress {
        from_port = 443
        to_port   = 443
        protocol  = "tcp"
        security_groups = [aws_security_group.secgrp_web_servers.id]
        description = "Allow HTTPS outbound"
    }
}

#bastian servers - Allow RDP in and SSH out to manager other servers
resource "aws_security_group" "secgrp_bastian_servers" {
    name = "secgrp_bastianservers"
    description = "Security group for bastias servers"
    vpc_id = var.vpc_id

    ingress {
        from_port = 3389
        to_port   = 3389
        protocol  = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow RDP inbound"
    }

    egress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "allow ssh to web servers and db servers"
    }
}

#Default Group for All Member Servers
resource "aws_security_group" "secgrp_default" {
    name        = "secgrp_default"
    description = "Default Security Group for all EC2 Servers"
    vpc_id = var.vpc_id
}
  

