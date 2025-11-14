locals {
    common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    DeployedOn  = timestamp()
  }
}