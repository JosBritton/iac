# iac

Terraform configuration for homelab Proxmox virtual environment.

## Usage
1. Initialize terraform environment
```
terraform init
```
2. Apply terraform configuration
```
terraform apply
```

If some provides a file lock error for some VMs, this is due to multiple consecutive disk clones at once. You can safely run the above command again and it will likely be created correctly.
