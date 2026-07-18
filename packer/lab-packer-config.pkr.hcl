#Тригер для запуска packer-a(Нужно ввести любой символ:)(122323)

# Плагины
packer {
  required_plugins {
    openstack = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/openstack"
    }
  }
}

# Переменные
variable "image_name" {
  type    = string
  default = "web-server-base"
}

variable "flavor" {
  type    = string
  default = "STD2-2-4"
}

variable "source_image" {
  type    = string
  default = "a4e699d3-a66d-45e5-bb5d-70ea7c8de62d"
}

variable "network_id" {
  type    = string
  default = "0ebce582-d2d2-49a7-bb99-984192271f41"
}

variable "security_groups" {
  type    = list(string)
  default = ["packer"]
}

# Источник (source) — параметры образа
source "openstack" "ubuntu-nginx" {
  source_image        = var.source_image
  flavor              = var.flavor
  networks            = [var.network_id]
  availability_zone   = "MS1"
  volume_availability_zone = "MS1"
  ssh_username        = "ubuntu"
  ssh_timeout         = "3m"
  floating_ip_network = "internet"
  security_groups     = var.security_groups
  use_blockstorage_volume = true
  volume_size         = 10
  image_name          = "${var.image_name}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
}

# Сборка
build {
  sources = ["source.openstack.ubuntu-nginx"]

  provisioner "shell" {
    inline = [
      "echo 'Cleaning apt cache...'",
      "sudo rm -rf /var/lib/apt/lists/*",
      "sudo apt-get clean",
      
      "echo 'Updating system...'",
      "sudo apt-get update -y",

      "echo 'Installing nginx...'",
      "sudo apt-get install -y nginx",
      
      "echo 'Installing PHP...'",
      "sudo apt-get install -y software-properties-common",
      "sudo add-apt-repository -y ppa:ondrej/php",
      "sudo apt-get update -y",
      "sudo apt-get install -y php8.1-fpm php8.1-mysql php8.1-cli",
  
      "echo 'Configuring nginx...'",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      
      "echo 'Creating test page...'",
      "echo '<h1>Built with Packer</h1>' | sudo tee /var/www/html/index.html",
      
      "echo 'Cleaning up...'",
      "sudo apt-get clean",
      "sudo rm -rf /tmp/*",
      "sudo rm -rf /var/lib/apt/lists/*"
    ]
  }
}