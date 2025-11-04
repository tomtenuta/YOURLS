# Root Makefile – build/push image and drive Terraform deploys

ENV ?= prod
AWS_REGION ?= us-east-1
ECR_REPO ?= yourls
IMAGE_TAG ?= $(ENV)
# Build platform(s). Fargate uses linux/amd64. On Apple Silicon, use buildx.
PLATFORMS ?= linux/amd64

ACCOUNT_ID := $(shell aws sts get-caller-identity --query Account --output text)
ECR_URI := $(ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(ECR_REPO)
IMAGE := $(ECR_URI):$(IMAGE_TAG)

TF_DIR := terraform
TFVARS := terraform-$(ENV).tfvars.json

.PHONY: help print image ecr-login ecr-create docker-build docker-tag docker-push buildx-push push tf-init tf-plan tf-apply tf-destroy tf-set-image deploy

help:
	@echo "Targets:"
	@echo "  image           Show computed ECR image URI"
	@echo "  push            Login to ECR, ensure repo, build, tag and push image"
	@echo "  tf-init         Terraform init (in $(TF_DIR))"
	@echo "  tf-plan         Terraform plan  (uses $(TFVARS))"
	@echo "  tf-apply        Terraform apply (uses $(TFVARS))"
	@echo "  tf-destroy      Terraform destroy (uses $(TFVARS))"
	@echo "  tf-set-image    Update yourls_image_uri in $(TF_DIR)/$(TFVARS) to $(IMAGE)"
	@echo "  deploy          push + tf-set-image + tf-apply"

print: image

image:
	@echo $(IMAGE)

ecr-login:
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

ecr-create:
	@aws ecr describe-repositories --repository-names $(ECR_REPO) --region $(AWS_REGION) >/dev/null 2>&1 || \
	  aws ecr create-repository --repository-name $(ECR_REPO) --region $(AWS_REGION) >/dev/null

docker-build:
	docker build -t $(ECR_REPO):$(IMAGE_TAG) .

docker-tag:
	docker tag $(ECR_REPO):$(IMAGE_TAG) $(IMAGE)

docker-push:
	docker push $(IMAGE)

# Preferred: multi-arch aware push for linux/amd64 (works on Apple Silicon)
buildx-push:
	@docker buildx create --use --name yourls-builder 2>/dev/null || true
	docker buildx build --platform $(PLATFORMS) -t $(IMAGE) --push .

# Push will use buildx if available; falls back to classic build/tag/push
push: ecr-login ecr-create
	@if docker buildx version >/dev/null 2>&1; then \
		echo "Using docker buildx with --platform=$(PLATFORMS)"; \
		$(MAKE) buildx-push PLATFORMS=$(PLATFORMS); \
	else \
		echo "docker buildx not found; using classic build (may fail on non-amd64)"; \
		$(MAKE) docker-build docker-tag docker-push; \
	fi

tf-init:
	cd $(TF_DIR) && terraform init -upgrade

tf-plan:
	cd $(TF_DIR) && terraform plan -var-file=$(TFVARS)

tf-apply:
	cd $(TF_DIR) && terraform apply -auto-approve -var-file=$(TFVARS)

tf-destroy:
	cd $(TF_DIR) && terraform destroy -auto-approve -var-file=$(TFVARS)

# Update yourls_image_uri in tfvars using jq if present, otherwise sed fallback
tf-set-image:
	@if command -v jq >/dev/null 2>&1; then \
	  tmp=$$(mktemp); \
	  jq '.yourls_image_uri = "$(IMAGE)"' $(TF_DIR)/$(TFVARS) > $$tmp && mv $$tmp $(TF_DIR)/$(TFVARS); \
	  echo "Updated yourls_image_uri to $(IMAGE) using jq"; \
	else \
	  sed -i.bak -E 's#("yourls_image_uri"\s*:\s*").*(")#\1$(IMAGE)\2#' $(TF_DIR)/$(TFVARS); \
	  echo "Updated yourls_image_uri to $(IMAGE) using sed"; \
	fi

deploy: push tf-set-image tf-apply
	@echo "Deploy complete: $(IMAGE)"


