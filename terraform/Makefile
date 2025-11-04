ENV ?= dev
TFVARS := terraform-$(ENV).tfvars.json

.PHONY: init plan apply destroy output

init:
	terraform init

plan:
	terraform plan -var-file=$(TFVARS)

apply:
	terraform apply -auto-approve -var-file=$(TFVARS)

destroy:
	terraform destroy -auto-approve -var-file=$(TFVARS)

output:
	terraform output -json


