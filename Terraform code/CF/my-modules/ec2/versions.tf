#Use this until we create out own templates at a later time

# Get latest Windows Server 2019 AMI
data "aws_ami" "windows_2019" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base*"]
  }
}# Get latest RHEL 8.x AMI
data "aws_ami" "rhel_8" {
  most_recent = true
  owners      = ["309956199498"]
  filter {
    name   = "name"
    values = ["RHEL-8.*"]
  }
}