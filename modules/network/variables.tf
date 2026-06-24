variable "project_name" {
  type = string
}
variable "public_subnet_cidr" {
  default = "192.168.1.0/24"
}
variable "private_subnet_cidr" {
  default = "192.168.2.0/24"
}
variable "my_ip" {
  default = "0.0.0.0/0"
}
variable "ssh_public_key" {
  type = string
}