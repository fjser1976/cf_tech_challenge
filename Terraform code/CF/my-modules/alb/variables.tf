variable "vpc_id" {
    type        = string
    description = "vpc where to create load balancer"
}

variable "alb_subnets" {
    type        = list
    description = "list of subnets to attach alb to"
}

variable "target_instances" {
    type        = list
    description = "target instances for the load balancer"
}

variable "alb_sec_groups" {
    type         = list
    description  = "list of security groups for the ALB"
}