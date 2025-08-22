terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"  # Terraform registry
      version = "5.86.0"
    }
  }

  # Local backend - state in local file
  backend "local" {
    path = "terraform-stage.tfstate"
  }
}