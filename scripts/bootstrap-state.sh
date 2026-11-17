#!/usr/bin/env bash
# One-time setup: creates the storage account that holds the Terraform state.
#
# This is the only thing created by hand. Terraform cannot store its state in
# a storage account that it still has to create itself (chicken-and-egg).
#
# Usage:  az login && ./scripts/bootstrap-state.sh
set -euo pipefail

LOCATION="${LOCATION:-westeurope}"
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-tfstate}"
CONTAINER="${CONTAINER:-tfstate}"
# Storage account names are globally unique: lowercase letters and digits only.
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:-sttfstate$(openssl rand -hex 4)}"

echo "Creating resource group ${RESOURCE_GROUP}..."
az group create --name "${RESOURCE_GROUP}" --location "${LOCATION}" --output none

echo "Creating storage account ${STORAGE_ACCOUNT}..."
az storage account create \
  --name "${STORAGE_ACCOUNT}" \
  --resource-group "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --output none

# Versioning keeps older copies of the state, so a broken state can be restored.
az storage account blob-service-properties update \
  --account-name "${STORAGE_ACCOUNT}" \
  --resource-group "${RESOURCE_GROUP}" \
  --enable-versioning true \
  --output none

# Access to the state goes through Entra ID (no storage account keys).
USER_ID="$(az ad signed-in-user show --query id --output tsv)"
ACCOUNT_ID="$(az storage account show --name "${STORAGE_ACCOUNT}" --resource-group "${RESOURCE_GROUP}" --query id --output tsv)"

az role assignment create \
  --assignee-object-id "${USER_ID}" \
  --assignee-principal-type User \
  --role "Storage Blob Data Contributor" \
  --scope "${ACCOUNT_ID}" \
  --output none

az storage container create \
  --name "${CONTAINER}" \
  --account-name "${STORAGE_ACCOUNT}" \
  --auth-mode login \
  --output none

cat <<CONFIG

Done. Put this in backend.hcl:

resource_group_name  = "${RESOURCE_GROUP}"
storage_account_name = "${STORAGE_ACCOUNT}"
container_name       = "${CONTAINER}"
key                  = "secure-webapp.dev.tfstate"
use_azuread_auth     = true
CONFIG
