variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "db_sg_id" { type = string }
variable "db_name" { default = "appdb" }
variable "db_user" { default = "appuser" }
variable "db_ip" { type = string }