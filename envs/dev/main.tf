#Тригер для запуска(Нужно ввести любой символ:)(122323)
terraform {
  required_providers {
    vkcs = {
      source  = "vk-cs/vkcs"
      version = "~> 0.15.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }

  backend "s3" {
    bucket = "terraform-state-final-lab"
    key    = "dev/terraform.tfstate"
    region   = "ru-msk"
    endpoints = {
      s3 = "https://hb.ru-msk.vkcloud-storage.ru"
    }
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
}

provider "vkcs" {}

module "network" {
  source              = "../../modules/network"
  project_name        = var.project_name
  my_ip               = var.my_ip
  ssh_public_key      = var.ssh_public_key
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
}

module "compute" {
  source         = "../../modules/compute"
  project_name   = var.project_name
  web_count      = var.web_count
  image_id       = var.image_id
  vpc_id         = module.network.vpc_id
  subnet_id      = module.network.private_subnet_id
  bastion_sg_id  = module.network.bastion_sg_id
  web_sg_id      = module.network.web_sg_id
  keypair_name   = module.network.keypair_name
  bastion_ip     = var.bastion_ip
  web_ip_base    = var.web_ip_base
}

module "loadbalancer" {
  source       = "../../modules/loadbalancer"
  project_name = var.project_name
  subnet_id    = module.network.public_subnet_id
  lb_sg_id     = module.network.lb_sg_id
  web_ips      = module.compute.web_private_ips
}

module "database" {
  source       = "../../modules/database"
  project_name = var.project_name
  vpc_id       = module.network.vpc_id
  db_sg_id     = module.network.db_sg_id
  db_ip        = var.db_ip
  depends_on   = [module.network.private_router_interface]
}