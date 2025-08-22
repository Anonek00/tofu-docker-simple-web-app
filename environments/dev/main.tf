# AWS provider config
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "tofu-docker-aws-infrastructure"
      Environment = "dev"
      ManagedBy   = "Anonek with OpenTofu"
    }
  }
}

# Local variables
locals {
  environment = "dev"
  
  common_tags = {
    Environment = local.environment
    Project     = "tofu-docker-aws-infrastructure"
    Owner       = "DevOps Team"
  }
}

# VPC Module include
module "networking" {
  source = "../../modules/vpc"
  
  environment        = local.environment
  vpc_cidr          = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
}

# Security Module include
module "security" {
  source = "../../modules/security"
  
  vpc_id            = module.networking.vpc_id
  environment       = local.environment
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
}

# EC2 Module include
module "EC2" {
  source = "../../modules/EC2"
  
  subnet_ids         = module.networking.public_subnet_ids
  security_group_ids = [module.security.web_security_group_id]
  environment        = local.environment
  instance_type      = var.instance_type
  key_pair_name      = var.key_pair_name
  instance_count     = var.instance_count
}

# Variables
variable "aws_region" {
  description = "Region AWS"
  type        = string
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "CIDR dla VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Strefy dostępności"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnets CIDRS"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "allowed_ssh_cidrs" {
  description = "IP allowed to SSH into EC2 instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_pair_name" {
  description = "SSH key pair name that should be used to connect with EC2 instance"
  type        = string
  default     = "dev-key"
}

variable "instance_count" {
  description = "Deployed instances count"
  type        = number
  default     = 1
}

# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "instance_public_ips" {
  description = "EC2 instance public IP"
  value       = module.EC2.public_ips
}

output "instance_public_dns" {
  description = "EC2 instance public DNS name"
  value       = module.EC2.public_dns
}

output "application_urls" {
  description = "Web Application URL"
  value       = [for dns in module.EC2.public_dns : "http://${dns}"] # Set to show EC2 instance AWS provided DNS. However it can be set for custom domain managed by AWS Load Balancer
}