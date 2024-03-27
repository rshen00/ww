terraform {
  required_version = ">= 1.0.0"

  backend "local" {
    path = "state/terraform.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}