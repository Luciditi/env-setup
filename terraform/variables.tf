variable "AWS_ACCESS_KEY_IAM" {
  description = "The AWS access key for admin role auth."
  type        = string
}
variable "AWS_SECRET_KEY_IAM" {
  description = "The AWS secret key for admin role auth."
  type        = string
}

variable "AWS_ADMIN_ARN" {
  description = "The AWS ARN of admin role."
  type        = string
}

variable "name" {
  default     = "env-setup"
  description = "The unique name for the AWS resources."
  type        = string
}

variable "macos_version" {
  default     = "Sonoma"
  description = "The version of macos to test on."
  type        = string
}

variable "environment" {
  default     = "temp"
  description = "The environment prefix string for the AWS resources."
  type        = string
}

variable "region" {
  default     = "us-east-1"
  description = "The default AWS region for AWS resources."
  type        = string
}

variable "hosts" {
  description = "The list of hosts to enable for testing."
  type        = map(bool)
  default = {
    linux = true
    macos = true
  }
}

locals {
  stack_name = "${var.environment}-${var.name}"
  # which subnet in the default VPC to pick for deployment
  # based on Mac dedicated host availability this might need to change.
  default_subnet = 1
  region         = var.region
  foo            = "bar"
  common_tags = {
    "Name"        = local.stack_name
    "Environment" = var.environment
    "Source"      = "env-setup"
  }
}
