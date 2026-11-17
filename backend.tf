# Remote state in Azure Storage, so the state file is:
#   - never stored on a laptop or committed to Git
#   - locked while someone is running a plan/apply
#   - encrypted at rest and versioned
#
# The actual values are passed in at init time (see backend.hcl.example):
#   terraform init -backend-config=backend.hcl
terraform {
  backend "azurerm" {}
}
