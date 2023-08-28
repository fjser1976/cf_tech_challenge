
# Builds the first (baseline) AD under a new account
resource "aws_directory_service_directory" "this_main_ad" {
    name                                    = var.ad_full_name
    short_name                              = var.ad_short_name
    desired_number_of_domain_controllers    = 2
    description                             = var.ad_description
    password                                = var.ad_default_password
    edition                                 = var.ad_edition
    type                                    = var.ad_type
    vpc_settings {
        vpc_id     = var.vpc_id
        subnet_ids = [var.ad_subnet_az1, var.ad_subnet_az2]
    }

    tags = {
        AWS_Managed = "True",
        Domain = var.ad_full_name,
        Site = "Primary",
            }
    lifecycle {
        ignore_changes = [
            password,
        ]
    }
}
 
