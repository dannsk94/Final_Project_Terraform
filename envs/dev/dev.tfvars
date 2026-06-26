project_name   = "lab7-dev"
web_count = 1
public_subnet_cidr = "192.168.1.0/24"
private_subnet_cidr = "192.168.2.0/24"
# Для правильного распределения по подсетям используем фиксированные ip-адреса
bastion_ip  = "192.168.1.50"
web_ip_base = "192.168.2"
db_ip       = "192.168.2.200"