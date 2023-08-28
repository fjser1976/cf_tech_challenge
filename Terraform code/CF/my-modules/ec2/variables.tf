variable "server_instance_type" {
  type        = string
  description = "EC2 instance type for server"
  default     = "t3a.micro"
}
variable "associate_public_ip_address" {
  type        = string
  description = "Associate a public IP address to the EC2 instance"
  default     = "false"
}
variable "server_root_volume_size" {
  type        = number
  description = "Volume size of root volume of Server"
  default     = "100"
}
variable "server_root_volume_type" {
  type        = string
  description = "Volume type of root volume of Server."
  default     = "gp3"
}
variable "ssh_key" {
  type        = string
  description = "Key Name to use for accessing system post creation"
}

variable "os_version" {
  type        = string
  description = "OS type to install"
  default     = "Windows Server 2019"
}

variable "subnet_ids" {
  type        = list
  description = "subnet Ids that will host the VMs"
  default     = []
}

variable "security_groups" {
  type        = list
  description = "List of Security Groups for the VM"
  default     = ["default"]
}

variable "instance_names" {
  type = list
  description = "List of instances to be created"
  default     = []
}




