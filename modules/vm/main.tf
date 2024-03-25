terraform {
  required_version = ">= 1.7.3"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc1"
    }
  }
}

resource "proxmox_vm_qemu" "vm" {
  name             = var.name
  clone            = var.clone
  agent            = 1
  full_clone       = true
  automatic_reboot = false
  target_node      = "pve1"
  onboot           = true
  vm_state         = "running"
  cores            = 8
  sockets          = 1
  cpu              = "host"  # host disables live migration
  memory           = var.memory
  balloon          = var.memory
  scsihw           = "virtio-scsi-single"
  qemu_os          = "l26"
  boot             = "order=scsi0"
  startup          = "${var.startuporder}"
  tags             = "${var.tag};terraform"

  ciuser                  = "${var.ciuser}"
  os_type                 = "cloud-init"
  cloudinit_cdrom_storage = "vmstore"

  ipconfig0  = var.net.address == "dhcp" ? "ip=dhcp" : "ip=${var.net.address}/${var.net.prefixlength},gw=${var.net.gateway}"
  nameserver = var.nameserver
  sshkeys    = <<-EOF
  ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFrhR6+9ezjCW4Bjrm1drH3/bbYS2/1jpbrv9BbDP0iP
  ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIINuLBOmsqpSkruNXNnFiup0AbQwat/AtfFgq4RJvEs7
  EOF

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
          storage = "vmstore"
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
