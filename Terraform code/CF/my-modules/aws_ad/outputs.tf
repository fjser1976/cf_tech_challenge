output "ad_id" {
  description = "ID of the main AD"
  value       = concat(aws_directory_service_directory.this_main_ad.*.id, [""])[0]
}

output "ad_dns" {
  description = "DNS Server IPs"
  value       = concat(aws_directory_service_directory.this_main_ad.*.dns_ip_addresses, [""])[0]
  }

 output "ad_shortname" {
   description = "AD shortname"
   value       = concat(aws_directory_service_directory.this_main_ad.*.short_name, [""])[0]
 }

output "ad_name" {
  description = "AD FQDN"
  value       = concat(aws_directory_service_directory.this_main_ad.*.name, [""])[0]
}

output "ad_security_group" {
  description = "AD Security Group"
  value       = concat(aws_directory_service_directory.this_main_ad.*.security_group_id, [""])[0]
}

