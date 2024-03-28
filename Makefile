.terraform/modules/modules.json: main.tf
	terraform init

.PHONY: apply
apply: .terraform/modules/modules.json
	terraform apply

.PHONY: clean
clean:
	rm -f terraform.tfstate
	rm -f terraform.tfstate.backup
