locals {
  # One naming pattern for every resource: <type>-<project>-<environment>
  name_suffix = "${var.project}-${var.environment}"

  # Key Vault and Web App names must be globally unique, so they get a short
  # random suffix.
  unique_suffix = random_string.suffix.result

  tags = merge(
    {
      project     = var.project
      environment = var.environment
      managed_by  = "terraform"
    },
    var.extra_tags
  )
}
