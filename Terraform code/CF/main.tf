module "pki" {
    source      = "./my-modules/pki"
}

module "vpc" {
    source              = "./my-modules/vpc_main"
    vpc_cidr            = var.vpc_cidr
    public_subnets      = var.public_nets
    private_subnets     = var.private_nets
    db_subnets          = var.db_nets
    azs                 = var.avail_zones
}

module "security_groups" {
     source              = "./my-modules/security_groups"
     vpc_id              = module.vpc.vpc_id
}

module "alb" {
     source              = "./my-modules/alb"
     vpc_id              = module.vpc.vpc_id
     alb_subnets         = module.vpc.public_subnets
     target_instances    = module.ec2_webservers.instance_ids
     alb_sec_groups      = [module.security_groups.security_grp_webserver]
}

module "ec2_webservers" {
    source                      = "./my-modules/ec2"
    server_instance_type        = var.linux_type
    associate_public_ip_address = "false" 
    server_root_volume_size     = var.linux_vol_size
    server_root_volume_type     = var.vol_type
    ssh_key                     = module.pki.ec2_public_key
    os_version                  = var.linux_image
    subnet_ids                  = module.vpc.private_subnets
    security_groups             = [module.security_groups.security_grp_webserver]
    instance_names              = var.linux_hostnames
}

 module "ec2_bastianservers" {
    source                      = "./my-modules/ec2"
    server_instance_type        = var.win_type
    associate_public_ip_address = "true" 
    server_root_volume_size     = var.win_vol_size
    server_root_volume_type     = var.vol_type
    ssh_key                     = module.pki.ec2_public_key
    os_version                  = var.win_image
    subnet_ids                  = module.vpc.public_subnets
    security_groups             = [module.security_groups.security_grp_bastianserver]
    instance_names              = var.win_hostnames
}

module "route_53" {
    source                      = "./my-modules/route_53"
    domain_name                 = var.domain_name
    sub_domain_name             = var.sub_domain_name
    ttl                         = var.ttl
    records                     = var.records
}