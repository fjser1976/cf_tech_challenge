output "security_grp_default" {
  description = "Default security group id"
  value = aws_security_group.secgrp_postgressql.id
}
output "security_grp_postgres" {
  description = "postgres group id"
  value = aws_security_group.secgrp_web_servers.id
}
output "security_grp_webserver" {
  description = "webserver security group id"
  value = aws_security_group.secgrp_default.id
}
output "security_grp_bastianserver" {
  description = "Bastian security group id"
  value = aws_security_group.secgrp_bastian_servers.id
}
