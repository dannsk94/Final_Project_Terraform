# Бастион
resource "vkcs_compute_instance" "bastion" {
  name      = "${var.project_name}-bastion"
  flavor_id = var.flavor_id
  image_id  = var.image_id
  key_pair  = var.keypair_name

  network {
    uuid = var.vpc_id
    fixed_ip_v4 = var.bastion_ip
  }

  security_group_ids = [var.bastion_sg_id]

  block_device {
    uuid                  = var.image_id
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = 10
    delete_on_termination = true
  }

  lifecycle {
    ignore_changes = [image_id]
  }
}

# Floating IP для бастиона
resource "vkcs_networking_floatingip" "bastion" {
  pool = "internet"
}

resource "vkcs_networking_floatingip_associate" "bastion" {
  floating_ip = vkcs_networking_floatingip.bastion.address
  port_id     = vkcs_compute_instance.bastion.network[0].port
}

# Веб-серверы
resource "vkcs_compute_instance" "web" {
  count = var.web_count

  name      = "${var.project_name}-web-${count.index + 1}"
  flavor_id = var.flavor_id
  image_id  = var.image_id
  key_pair  = var.keypair_name

  network {
    uuid = var.vpc_id
    fixed_ip_v4 = "${var.web_ip_base}.${100 + count.index}"
  }

  security_group_ids = [var.web_sg_id]

  block_device {
    uuid                  = var.image_id
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = 10
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash
    systemctl start nginx
    echo "<h1>Web Server ${count.index + 1}</h1>" > /var/www/html/index.html
  EOF

  lifecycle {
    ignore_changes = [image_id]
  }
}