output "bastion_public_ip" { value = module.compute.bastion_public_ip }
output "bastion_private_ip" { value = module.compute.bastion_private_ip }
output "bastion_private_network_ip" { value = module.compute.bastion_private_network_ip }
output "load_balancer_ip" { value = module.loadbalancer.lb_public_ip }
output "web_private_ips" { value = module.compute.web_private_ips }
output "db_host" { value = module.database.db_host }
output "db_name" { value = module.database.db_name }
output "db_user" { value = module.database.db_user }