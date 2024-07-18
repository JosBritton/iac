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
  template_name = "debian12v3"
  vm = {
    dns = [
      {
        name = "ns1"
        node = "pve2"
      },
      {
        name = "ns2"
        node = "pve1"
      },
      {
        name = "ns3"
        node = "pve2"
      }
    ]
    dhcp = [
      {
        name = "dhcp1"
        node = "pve2"
        # additional_disks = {
        #   scsi2 = [{
        #     size_gigabytes = 4
        #   }]
        # }
      }
    ]
    lb = [
      {
        name = "lb1"
        node = "pve2"
      },
      {
        name = "lb2"
        node = "pve1"
      }
    ]
    bt = [
      {
        name = "bt1"
        node = "pve2"
      },
      {
        name = "bt2"
        node = "pve1"
      }
    ]
    k8s = [
      {
        name = "k8s1"
        node = "pve2"
      },
      {
        name = "k8s2"
        node = "pve1"
      },
      {
        name = "k8s3"
        node = "pve1"  # pve3
      },
    ]
    etcd = [
      {
        name = "etcd1"
        node = "pve1"
      },
      {
        name = "etcd2"
        node = "pve2"
      },
      {
        name = "etcd3"
        node = "pve1"  # pve3
      }
    ]
  }
}

provider "proxmox" {
  pm_tls_insecure     = false
  pm_api_url          = var.pm_api_url
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
}

## root modules
module "dns" {
  for_each = { for i, vm in local.vm.dns : i => vm }
  source = "./modules/vm"
  memory = 1024
  clone  = local.template_name
  name   = each.value.name
  node   = each.value.node
  vmid   = lookup(each.value, "vmid", each.key + 101)
  disk_size_gigabytes = 10
  net = {
    address      = cidrhost("10.0.3.0/24", each.key + 10)
    prefixlength = 24
    gateway      = "10.0.3.1"
  }
  tag            = "dns"
  ciuser         = var.ciuser
  startuporder   = each.key + 1
  vlan           = 3
  nameserver   = "1.1.1.1 1.0.0.1"
}

module "dhcp" {
  for_each = { for i, vm in local.vm.dhcp : i => vm }
  source = "./modules/vm"
  memory = 1024
  needs_migratable = true
  clone  = local.template_name
  name   = each.value.name
  node   = each.value.node
  vmid   = lookup(each.value, "vmid", each.key + 201)
  additional_disks    = lookup(each.value, "additional_disks", {})
  disk_size_gigabytes = 10
  net = {
    address      = cidrhost("10.0.3.0/24", each.key + 16)
    prefixlength = 24
    gateway      = "10.0.3.1"
  }
  tag            = "dhcp"
  ciuser         = var.ciuser
  startuporder   = each.key + 10
  vlan           = 3
  nameserver   = "10.0.3.10 10.0.3.11"
}

module "lb" {
  for_each = { for i, vm in local.vm.lb : i => vm }
  source = "./modules/vm"
  memory = 1024
  clone  = local.template_name
  name   = each.value.name
  node   = each.value.node
  vmid   = lookup(each.value, "vmid", each.key + 301)
  additional_disks    = lookup(each.value, "additional_disks", {})
  disk_size_gigabytes = 10
  net = {
    address      = cidrhost("10.0.3.0/24", each.key + 8)
    prefixlength = 24
    gateway      = "10.0.3.1"
  }
  tag          = "lb"
  ciuser       = var.ciuser
  startuporder = each.key + 25
  vlan         = 3
  nameserver   = "10.0.3.10 10.0.3.11"
}

module "bt" {
  for_each = { for i, vm in local.vm.bt : i => vm }
  source = "./modules/vm"
  memory = 4096
  needs_migratable = true
  clone  = local.template_name
  name   = each.value.name
  node   = each.value.node
  vmid   = lookup(each.value, "vmid", each.key + 401)
  additional_disks    = lookup(each.value, "additional_disks", {})
  disk_size_gigabytes = 10
  net = {
    address      = cidrhost("10.0.3.0/24", each.key + 24)
    prefixlength = 24
    gateway      = "10.0.3.1"
  }
  tag          = "bt"
  ciuser       = var.ciuser
  startuporder = each.key + 30
  vlan         = 3
  nameserver   = "10.0.3.10 10.0.3.11"
}

module "k8s" {
  for_each = { for i, vm in local.vm.k8s : i => vm }
  source = "./modules/vm"
  memory = 10240
  needs_migratable = true
  clone  = local.template_name
  name   = each.value.name
  node   = each.value.node
  vmid   = lookup(each.value, "vmid", each.key + 501)
  additional_disks    = lookup(each.value, "additional_disks", {})
  disk_size_gigabytes = 30
  net = {
    address      = cidrhost("10.0.12.0/24", each.key + 11)
    prefixlength = 24
    gateway      = "10.0.12.1"
  }
  tag          = "k8s"
  ciuser       = var.ciuser
  startuporder = each.key + 1000
  vlan         = 12
  nameserver   = "10.0.3.10 10.0.3.11"
}

module "etcd" {
  for_each = { for i, vm in local.vm.etcd : i => vm }
  source = "./modules/vm"
  memory = 5120
  needs_migratable = true
  clone  = local.template_name
  name   = each.value.name
  node   = each.value.node
  vmid   = lookup(each.value, "vmid", each.key + 601)
  additional_disks    = lookup(each.value, "additional_disks", {})
  disk_size_gigabytes = 10
  net = {
    address      = cidrhost("10.0.12.0/24", each.key + 21)
    prefixlength = 24
    gateway      = "10.0.12.1"
  }
  tag            = "etcd"
  ciuser         = var.ciuser
  startuporder   = each.key + 1
  vlan           = 12
  nameserver   = "10.0.3.10 10.0.3.11"
}
