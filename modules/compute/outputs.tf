output "bastion_public_ip" { value = vkcs_networking_floatingip.bastion.address }
output "bastion_private_ip" { value = vkcs_compute_instance.bastion.access_ip_v4 }
output "web_private_ips" { value = vkcs_compute_instance.web[*].access_ip_v4 }