terraform {
  required_version = "~> 1.9"

  experiments = [module_variable_optional_attrs]  # 👈 This line enables optional object attributes

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.93.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.3"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.3"
    }
  }
}
