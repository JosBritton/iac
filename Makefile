export DEVMODE=1
.terraform/modules/modules.json: main.tf
	@[ ! -z $(DEVMODE) ] || terraform init

.PHONY: apply
apply: .terraform/modules/modules.json
	terraform apply

.PHONY: plan
plan: .terraform/modules/modules.json
	terraform plan

.PHONY: clean
clean:
	rm -f terraform.tfstate
	rm -f terraform.tfstate.backup
