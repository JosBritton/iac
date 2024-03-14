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

  template_name = "packer-debian12-genericcloud"

  # host part IP address offset from subnet e.g. 16 = 10.0.0.0/24 -> 10.0.0.16
  # later, use index of root module count to increment from offset to partition the subnet
  ip_host_offset = {
    envoylb           = 16
    k8s               = 32
    k8swork           = 48
  }
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
  memory = 3584
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
}

module "dhcp" {
  source = "./modules/vm"
  memory = 3584
  clone  = local.template_name
  name   = "dhcp${count.index + 1}"
  disk_size_gigabytes = 10
  net = {
    address      = cidrhost("10.0.3.0/24", count.index + 16)
    prefixlength = 24
    gateway      = "10.0.3.1"
  }
  count          = 2
  tag            = "dhcp"
  ciuser         = var.ciuser
  startuporder   = count.index + 10
  vlan           = 3
}

module "lb" {
  source = "./modules/vm"
  memory = 3584
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
}

module "k8s" {
  source = "./modules/vm"
  memory = 4096
  clone  = local.template_name
  name   = "k8s${count.index + 1}"
  disk_size_gigabytes = 48
  net = {
    address = "dhcp"
  }
  count        = 5
  tag          = "k8s"
  ciuser       = var.ciuser
  startuporder = count.index + 1000
  vlan         = 12
}
