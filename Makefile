PROXMOX_PARALLELISM=4

.terraform/modules/modules.json: main.tf
	terraform init

.PHONY: apply
apply: .terraform/modules/modules.json
	terraform apply -parallelism=$(PROXMOX_PARALLELISM)
