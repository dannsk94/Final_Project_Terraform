project_name   = "lab7-prod"
public_subnet_cidr = "192.168.11.0/24"
private_subnet_cidr = "192.168.12.0/24"
# Для правильного распределения по подсетям используем фиксированные ip-адреса
bastion_ip  = "192.168.11.50"
bastion_private_ip = "192.168.12.50"
web_ip_base = "192.168.12"
db_ip       = "192.168.12.200"