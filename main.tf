terraform {
  required_version = ">= 1.7.3"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc1"
    }
  }
}

locals {
  ### REQUIRED SECRETS, define in *.auto.tfvars
  secrets = {
    tsig_key            = var.tsig_key
    pm_api_url          = var.pm_api_url
    pm_api_token_id     = var.pm_api_token_id
    pm_api_token_secret = var.pm_api_token_secret 
  }

  template_name = "debian12v3"
}

provider "proxmox" {
  pm_tls_insecure     = false
  pm_api_url          = local.secrets.pm_api_url
  pm_api_token_id     = local.secrets.pm_api_token_id
  pm_api_token_secret = local.secrets.pm_api_token_secret
}

######
### root modules
######

module "dns" {
  source = "./modules/vm"
  memory = 1024
  clone  = local.template_name
  name   = "ns${count.index + 1}"
  disk_size_gigabytes = 10
  net = {
    address      = cidrhost("10.0.3.0/24", count.index + 10)
    prefixlength = 24
    gateway      = "10.0.3.1"
  }
  count          = 4
  tag            = "dns"
  ciuser         = var.ciuser
  startuporder   = count.index + 1
  vlan           = 3
  nameserver   = "1.1.1.1 1.0.0.1"
}

module "dhcp" {
  source = "./modules/vm"
  memory = 1024
  clone  = local.template_name
  name   = "dhcp${count.index + 1}"
  disk_size_gigabytes = 10
  net = {
    address      = cidrhost("10.0.3.0/24", count.index + 16)
    prefixlength = 24
    gateway      = "10.0.3.1"
  }
  count          = 1
  tag            = "dhcp"
  ciuser         = var.ciuser
  startuporder   = count.index + 10
  vlan           = 3
  nameserver   = "10.0.3.10 10.0.3.11"
}

module "lb" {
  source = "./modules/vm"
  memory = 1024
  clone  = local.template_name
  name   = "lb${count.index + 1}"
  disk_size_gigabytes = 10
  net = {
    address      = cidrhost("10.0.3.0/24", count.index + 8)
    prefixlength = 24
    gateway      = "10.0.3.1"
  }
  count        = 2
  tag          = "lb"
  ciuser       = var.ciuser
  startuporder = count.index + 25
  vlan         = 3
  nameserver   = "10.0.3.10 10.0.3.11"
}

module "bt" {
  source = "./modules/vm"
  memory = 2048
  clone  = local.template_name
  name   = "bt${count.index + 1}"
  disk_size_gigabytes = 28
  net = {
    address      = "dhcp"
  }
  count        = 1
  tag          = "bt"
  ciuser       = var.ciuser
  startuporder = count.index + 30
  vlan         = 3
  nameserver   = "10.0.3.10 10.0.3.11"
}

module "k8s" {
  source = "./modules/vm"
  memory = 5120
  clone  = local.template_name
  name   = "k8s${count.index + 1}"
  disk_size_gigabytes = 28
  net = {
    address      = cidrhost("10.0.12.0/24", count.index + 11)
    prefixlength = 24
    gateway      = "10.0.12.1"
  }
  count        = 5
  tag          = "k8s"
  ciuser       = var.ciuser
  startuporder = count.index + 1000
  vlan         = 12
  nameserver   = "10.0.3.10 10.0.3.11"
}
