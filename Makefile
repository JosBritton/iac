PROXMOX_PARALLELISM=3

.terraform/modules/modules.json: main.tf
	terraform init

.PHONY: apply
apply: .terraform/modules/modules.json
	terraform apply -parallelism=$(PROXMOX_PARALLELISM)
