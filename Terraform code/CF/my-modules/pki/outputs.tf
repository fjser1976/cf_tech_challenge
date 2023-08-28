output "ec2_public_key" {
  description = "Public Key for EC2 Windows Instances"
  value = aws_key_pair.this.key_name
}
