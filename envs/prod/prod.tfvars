project_name   = "lab7-prod"
my_ip          = "0.0.0.0/0"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC59nQR828VzmpilXOeSwI0D9EUSC0tYIXntTFsQlhPe0JM0wTW8e7e6IZ3x3NZKzKrykbW2S2mfrcU7F4XL4Xh4Sj6fCV0jNKFs4zX15uxURIj8UwEH2TWwl6Ir3UdIn7r/63BY4ohq8vL7G7F/sXIFo3hDXhkXtqjAdKO/1jyKyWtwVykxaRbsW8ns4zlNRfnO0RCpCfg88ek6F0cv0Zb2eIJM5ms+Jkn4j0/3f25knz0SuaScmkKw5wRCHTHYcgNv/djsB0LrGYKKqfNV0jrzB7gOEOmiJ8jUCBd6iausfrI701PgXxEcM97pSO5/7RjD/aHMfjjVvO2Wm8D3dFV"
web_count = 2
public_subnet_cidr = "192.168.11.0/24"
private_subnet_cidr = "192.168.12.0/24"
# Для правильного распределения по подсетям используем фиксированные ip-адреса
bastion_ip  = "192.168.11.50"
web_ip_base = "192.168.12"
db_ip       = "192.168.12.200"