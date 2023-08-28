 locals {
     #image_id = data.aws_ami.rhel_8.id 
     image_id = var.os_version == "Windows Server 2019" ? data.aws_ami.windows_2019.id : data.aws_ami.rhel_8.id 
 }

# Create EC2 Instance
resource "aws_instance" "this" {
    count = length(var.instance_names)
    ami = local.image_id
    instance_type = var.server_instance_type
    subnet_id = var.subnet_ids[count.index]
    vpc_security_group_ids = var.security_groups
    key_name = var.ssh_key
    #ecs_associate_public_ip_address = var.associate_public_ip_address
    # root disk
    root_block_device {
      volume_size           = var.server_root_volume_size
      volume_type           = var.server_root_volume_type
      delete_on_termination = false
      encrypted             = true
    }  


  lifecycle {
    #if any of these values change in future builds, do not destroy the existing resources because of it  
    ignore_changes = [
        ami,
        key_name,
        root_block_device,
        instance_type,
    ]
  }
  tags = {
        Name    = "${var.instance_names[count.index]}"
        OS      = var.os_version
  }
}

