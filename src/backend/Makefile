BOOTSTRAP_DIR=bootstrap
INFRA_DIR=infrastructure
BACKEND_JSON=$(INFRA_DIR)/backend.tf.json
VARS_JSON=backend-secrets.auto.tfvars.json

ACCESS_KEY= YOUR_ACCESS_KEY
SECRET_KEY= YOUR_SECRET_KEY

.PHONY: all bootstrap extract generate-backend init-infra apply-infra

# all: bootstrap extract generate-backend init-infra apply-infra

all: generate-backend

# bootstrap:
# 	cd $(BOOTSTRAP_DIR) && terraform init && terraform apply -auto-approve

# extract:
# 	cd $(BOOTSTRAP_DIR) && terraform output -json | jq 'map_values(.value)' > $(VARS_JSON)

generate-backend:
	@bash -c 'cat > $(BACKEND_JSON) <<EOF
{
  "terraform": {
    "backend": {
      "s3": {
        "endpoints": {
          "s3": "https://storage.yandexcloud.net"
        },
        "bucket": "yagavrin-tf-backend",
        "key": "terraform.tfstate",
        "region": "ru-central1",
        "access_key": "$$ACCESS_KEY",
        "secret_key": "$$SECRET_KEY",
        "skip_region_validation": true,
        "skip_credentials_validation": true
      }
    }
  }
}
EOF'
# init-infra:
# 	cd $(INFRA_DIR) && terraform init -migrate-state

# apply-infra:
# 	cd $(INFRA_DIR) && terraform apply -auto-approve
