resource "vkcs_lb_loadbalancer" "main" {
  name          = "${var.project_name}-lb"
  vip_subnet_id = var.subnet_id
  timeouts {
    delete = "10m"
  }
}

resource "vkcs_lb_listener" "http" {
  name            = "${var.project_name}-listener"
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = vkcs_lb_loadbalancer.main.id
}

resource "vkcs_lb_pool" "web" {
  name        = "${var.project_name}-pool"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = vkcs_lb_listener.http.id
}

resource "vkcs_lb_monitor" "web" {
  name        = "${var.project_name}-monitor"
  type        = "HTTP"
  delay       = 10
  timeout     = 5
  max_retries = 3
  url_path    = "/"
  pool_id     = vkcs_lb_pool.web.id
}

resource "vkcs_lb_member" "web" {
  count         = length(var.web_ips)
  name          = "${var.project_name}-member-${count.index + 1}"
  address       = var.web_ips[count.index]
  protocol_port = 80
  pool_id       = vkcs_lb_pool.web.id
  subnet_id     = var.subnet_id
}

resource "vkcs_networking_floatingip" "lb" {
  pool = "internet"
}

resource "vkcs_networking_floatingip_associate" "lb" {
  floating_ip = vkcs_networking_floatingip.lb.address
  port_id     = vkcs_lb_loadbalancer.main.vip_port_id
}