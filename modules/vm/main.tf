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
  node_hardware = {
    pve1 = {
      vmdisk = "tank"
      cores = 8
      sockets = 1
    }
    pve2 = {
      vmdisk = "tank"
      cores = 12
      sockets = 1
    }
  }
}

resource "proxmox_vm_qemu" "vm" {
  name             = var.name
  clone            = var.clone
  agent            = 1
  full_clone       = true
  automatic_reboot = false
  target_node      = var.node
  vmid             = var.vmid
  onboot           = true
  vm_state         = "running"

  cores            = var.needs_migratable ? min([for _, hw in local.node_hardware: hw.cores ]...) : local.node_hardware[var.node].cores
  sockets          = var.needs_migratable ? min([for _, hw in local.node_hardware: hw.sockets ]...) : local.node_hardware[var.node].sockets
  cpu              = var.needs_migratable ? "x86-64-v3" : "host"

  memory           = var.memory
  machine          = "q35"
  balloon          = var.memory
  scsihw           = "virtio-scsi-single"
  qemu_os          = "l26"
  boot             = "order=scsi0"
  startup          = "${var.startuporder}"
  tags             = "${var.tag};terraform"

  ciuser                  = "${var.ciuser}"
  # https://github.com/Telmate/terraform-provider-proxmox/pull/1049
  ciupgrade               = false
  os_type                 = "cloud-init"

  ipconfig0  = var.net.address == "dhcp" ? "ip=dhcp" : "ip=${var.net.address}/${var.net.prefixlength},gw=${var.net.gateway}"
  nameserver = var.nameserver
  sshkeys    = <<-EOF
  ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFrhR6+9ezjCW4Bjrm1drH3/bbYS2/1jpbrv9BbDP0iP
  ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIINuLBOmsqpSkruNXNnFiup0AbQwat/AtfFgq4RJvEs7
  EOF

  lifecycle {
    # prevent_destroy = true
    ignore_changes = [
      clone,
      full_clone,
      disks[0].scsi[0].scsi2,
      disks[0].scsi[0].scsi3,
      disks[0].scsi[0].scsi4,
      disks[0].scsi[0].scsi5,
      disks[0].scsi[0].scsi6,
      disks[0].scsi[0].scsi7,
      disks[0].scsi[0].scsi8,
      disks[0].scsi[0].scsi9,
      disks[0].scsi[0].scsi10,
      disks[0].scsi[0].scsi11,
      disks[0].scsi[0].scsi12,
      disks[0].scsi[0].scsi13,
      disks[0].scsi[0].scsi14,
      disks[0].scsi[0].scsi15,
      disks[0].scsi[0].scsi16,
      disks[0].scsi[0].scsi17,
      disks[0].scsi[0].scsi18,
      disks[0].scsi[0].scsi19,
      disks[0].scsi[0].scsi20,
      disks[0].scsi[0].scsi21,
      disks[0].scsi[0].scsi22,
      disks[0].scsi[0].scsi23,
      disks[0].scsi[0].scsi24,
      disks[0].scsi[0].scsi25,
      disks[0].scsi[0].scsi26,
      disks[0].scsi[0].scsi27,
      disks[0].scsi[0].scsi28,
      disks[0].scsi[0].scsi29
    ]
  }

  # make sure connection is successful before continuing
  connection {
    host    = var.net.address == "dhcp" ? self.ssh_host : var.net.address
    agent   = true
    type    = "ssh"
    timeout = "3m"
  }

  disks {
    scsi {
      scsi0 {
        disk {
          asyncio = "io_uring"
          replicate = true
          backup = true
          cache = "none"
          discard = true
          emulatessd = true
          format = "raw"
          iothread = true
          readonly = false
          size = var.disk_size_gigabytes
          storage = local.node_hardware[var.node].vmdisk
        }
      }
      scsi1 {
        cloudinit {
          storage = local.node_hardware[var.node].vmdisk
        }
      }
      # optional
      dynamic "scsi2" {
        for_each = var.additional_disks.scsi2[*]
        content {
          dynamic "disk" {
            for_each = var.additional_disks.scsi2[*]
            iterator = d
            content {
              asyncio = "io_uring"
              replicate = true
              backup = true
              cache = "none"
              discard = true
              emulatessd = true
              format = "raw"
              iothread = true
              readonly = false
              size = d.value.size_gigabytes
              storage = local.node_hardware[var.node].vmdisk
            }
          }
        }
      }
    }
  }

  network {
    bridge    = "vmbr0"
    firewall  = false
    link_down = false
    model     = "virtio"
    mtu       = 0
    queues    = 0
    rate      = 0
    tag       = var.vlan
  }

  serial {
    id = 0
    type = "socket"
  }

  vga {
    type = "serial0"
  }
}
