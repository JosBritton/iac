variable "name" {
  type        = string
  description = "The name of the VM instance."
}

variable "clone" {
  type        = string
  description = "The name of the VM instance to clone."
}

variable "memory" {
  type        = number
  description = "The amount of memory to allocate to the VM instance."
  validation {
    condition     = var.memory >= 1
    error_message = "Memory must be greater than or equal to 1 MB."
  }
}

variable "nameserver" {
  type        = string
  default     = ""
  description = "DNS server for guest."
}

variable "searchdomain" {
  type        = string
  default     = ""
  description = "DNS search domain suffix."
}

variable "net" {
  type = object({
    address      = string,
    gateway      = optional(string),
    prefixlength = optional(number)
  })
  default = {
    address = "dhcp"
  }
  description = "The network configuration for the VM instance."

  validation {
    condition     = var.net.address == "dhcp" || can(regex("^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$", var.net.address))
    error_message = "net.address is neither keyword `dhcp` nor a valid IPv4 address."
  }
  validation {
    condition     = var.net.address == "dhcp" || can(regex("^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$", var.net.gateway))
    error_message = "net.gateway is not a valid IPv4 address."
  }
  validation {
    condition     = var.net.address == "dhcp" ? true : can(regex("^\\d+$", var.net.prefixlength)) && var.net.prefixlength >= 0 && var.net.prefixlength <= 32
    error_message = "net.prefixlength is not a whole number between 0 and 32."
  }
  validation {
    condition     = var.net.address != var.net.gateway
    error_message = "net.address must be different than net.gateway."
  }
}

variable "disk_size_gigabytes" {
  type = number
  default = 16
  description = "Specify primary (disk id: scsi0) disk size in gigabytes."
}

variable "tag" {
  type = string
  default = ""
  description = "Specify a tag in Proxmox VE."
}

variable "ciuser" {
  type = string
  default = "user"
}

variable "startuporder" {
  type = number
  default = 1000
}

variable "vlan" {
  type    = number
  validation {
    condition     = var.vlan >= -1 && var.vlan <= 4096 && var.vlan != 0 && var.vlan != 1 && var.vlan != 4095
    error_message = "VLAN ID must be in range (-1,2-4094,4096). To disable VLAN tagging, set to -1."
  }

}

variable "node" {
  type = string
  description = "Specify target Proxmox node."
}

variable "vmid" {
  type = number
  default = null
}

variable "additional_disks" {
  type = object({
    scsi2 = optional(list(object({
      size_gigabytes = optional(string)
    })), [])
  })
  default = {}
}

variable "needs_migratable" {
  type = bool
  default = false
}
