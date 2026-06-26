data "vkcs_networking_router" "existing" {
  name = "router_4389"
}

resource "vkcs_networking_network" "vpc" {
  name = "${var.project_name}-vpc"
}

resource "vkcs_networking_subnet" "public" {
  name       = "${var.project_name}-public-subnet"
  network_id = vkcs_networking_network.vpc.id
  cidr       = var.public_subnet_cidr
}

resource "vkcs_networking_subnet" "private" {
  name       = "${var.project_name}-private-subnet"
  network_id = vkcs_networking_network.vpc.id
  cidr       = var.private_subnet_cidr
}

resource "vkcs_networking_router_interface" "public" {
  router_id = data.vkcs_networking_router.existing.id
  subnet_id = vkcs_networking_subnet.public.id
}

resource "vkcs_networking_router_interface" "private" {
  router_id = data.vkcs_networking_router.existing.id
  subnet_id = vkcs_networking_subnet.private.id
}

# Security Groups
resource "vkcs_networking_secgroup" "bastion_sg" {
  name = "${var.project_name}-bastion-sg"
}

# ВАЖНО: из-за особенностей VK Cloud при volume boot недостаточно открыть только порт 22.
# Требуется открыть весь диапазон TCP-портов для корректной работы SSH.

resource "vkcs_networking_secgroup_rule" "bastion_ssh" {
  direction         = "ingress"
  protocol          = "all"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = var.my_ip
  security_group_id = vkcs_networking_secgroup.bastion_sg.id
}

resource "vkcs_networking_secgroup" "web_sg" {
  name = "${var.project_name}-web-sg"
}
resource "vkcs_networking_secgroup_rule" "web_http" {
  direction         = "ingress"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = vkcs_networking_secgroup.web_sg.id
}
resource "vkcs_networking_secgroup_rule" "web_egress" {
  direction         = "egress"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = vkcs_networking_secgroup.web_sg.id
}

resource "vkcs_networking_secgroup" "db_sg" {
  name = "${var.project_name}-db-sg"
}
resource "vkcs_networking_secgroup_rule" "db_postgres" {
  direction         = "ingress"
  protocol          = "tcp"
  port_range_min    = 5432
  port_range_max    = 5432
  remote_ip_prefix  = var.private_subnet_cidr
  security_group_id = vkcs_networking_secgroup.db_sg.id
}

resource "vkcs_networking_secgroup" "lb_sg" {
  name = "${var.project_name}-lb-sg"
}
resource "vkcs_networking_secgroup_rule" "lb_http" {
  direction         = "ingress"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = vkcs_networking_secgroup.lb_sg.id
}

resource "vkcs_compute_keypair" "main" {
  name       = "${var.project_name}-key"
  public_key = var.ssh_public_key
}