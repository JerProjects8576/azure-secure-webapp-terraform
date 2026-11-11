# Authentication is handled outside the code:
#   - locally:        `az login` + the ARM_SUBSCRIPTION_ID environment variable
#   - GitHub Actions: OpenID Connect (no stored passwords or client secrets)
provider "azurerm" {
  features {
    key_vault {
      # Purge protection is on, so a destroyed vault stays recoverable for the
      # retention period instead of being wiped immediately.
      purge_soft_delete_on_destroy = false
    }

    resource_group {
      # Azure adds a few helper resources on its own (for example alert rules
      # for Application Insights). This lets `terraform destroy` clean up fully.
      prevent_deletion_if_contains_resources = false
    }
  }
}
