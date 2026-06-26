variable "project_name" { type = string }
variable "web_count" { type = number }
variable "vpc_id" { type = string }
variable "subnet_id" { type = string }
variable "bastion_ip" { type = string }
variable "bastion_private_ip" { type = string }
variable "web_ip_base" { type = string } 
variable "bastion_sg_id" { type = string }
variable "web_sg_id" { type = string }
variable "keypair_name" { type = string }
variable "flavor_id" { 
  default = "9cdbca68-5e15-4c54-979d-9952785ba33e" 
}
variable "image_id" {
  type    = string
  default = "a4e699d3-a66d-45e5-bb5d-70ea7c8de62d"
}