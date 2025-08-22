variable "vpc_cidr" {
  description = "WEB APP VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment name (dev/stage/prod)"
  type        = string
}

variable "availability_zones" {
  description = "AWS Frankfurt availability zones"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnets CIDRS"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}