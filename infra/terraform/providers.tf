# Define our providers

# Provider with assume role created above. This is
# the actual provider we'll use for most operations,
# note that it is the default
provider "aws" {
  region     = local.region
  access_key = var.AWS_ACCESS_KEY_IAM
  secret_key = var.AWS_SECRET_KEY_IAM
  assume_role {
    role_arn = var.AWS_ADMIN_ARN
  }
  default_tags {
    tags = local.common_tags
  }
}
