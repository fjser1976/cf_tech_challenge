output "instance_ids" {
  description = "List instances id"
  value = aws_instance.this[*].id
}
