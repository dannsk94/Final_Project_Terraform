variable "project_name" { type = string }
variable "my_ip" { type = string }
variable "ssh_public_key" { type = string }
variable "web_count" { type = number }
variable "image_id" { 
  type = string  
  default = "a4e699d3-a66d-45e5-bb5d-70ea7c8de62d" 
  }
variable "public_subnet_cidr" { type = string }
variable "private_subnet_cidr" { type = string }
variable "bastion_ip" { type = string }
variable "bastion_private_ip" { type = string }
variable "web_ip_base" { type = string }
variable "db_ip" { type = string }