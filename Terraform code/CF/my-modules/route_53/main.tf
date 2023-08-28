#creates the hosted zone in AWS
resource "aws_route53_zone" "my_hosted_zone" {
  name = var.domain_name
}


# resource "aws_acm_certificate" "my_certificate_request" {
#     domain_name               = var.domain_name
#     subject_alternative_names = ["*.{var.domain_name}"]
#     validation_method         = "DNS"

#     tags = {
#         Name : var.domain_name
#     }

#     lifecycle {
#         create_before_destroy = true
#     }
# }

resource "aws_route53_record" "cname_route53_record" {
  zone_id = aws_route53_zone.my_hosted_zone.zone_id # Replace with your zone ID
  name    = var.sub_domain_name 
  type    = "CNAME"
  ttl     = "60"
  records = var.records
}