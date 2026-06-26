data "vkcs_networking_network" "external" {
  name = "internet"
}

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

    network {
    uuid        = var.vpc_id
    fixed_ip_v4 = var.bastion_private_ip
  }

  security_group_ids = [var.bastion_sg_id]

  block_device {
    uuid                  = var.image_id
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = 10
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash
    apt-get update && apt-get install -y openssh-server
    systemctl enable ssh && systemctl start ssh
  EOF

  lifecycle {
    ignore_changes = [image_id]
  }
}

# Floating IP для бастиона
resource "vkcs_networking_floatingip" "bastion" {
  pool = data.vkcs_networking_network.external.name
}

data "vkcs_networking_port" "bastion" {
  fixed_ip   = var.bastion_ip
  network_id = var.vpc_id
  depends_on = [vkcs_compute_instance.bastion]
}

resource "vkcs_networking_floatingip_associate" "bastion" {
  floating_ip = vkcs_networking_floatingip.bastion.address
  port_id     = data.vkcs_networking_port.bastion.id
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
    apt-get update && apt-get install -y openssh-server nginx
    systemctl enable ssh && systemctl start ssh
    systemctl enable nginx && systemctl start nginx
    echo "<h1>Web Server ${count.index + 1}</h1>" > /var/www/html/index.html
  EOF

  lifecycle {
    ignore_changes = [image_id]
  }
}