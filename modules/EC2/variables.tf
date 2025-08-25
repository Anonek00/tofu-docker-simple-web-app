variable "subnet_ids" {
  description = "List subnet IDs assigned to EC2 instance"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List security group ID assigned to EC2 instance"
  type        = list(string)
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"  # Free tier 64-bit instance. Actual instance type depends on use case and requirements. Can be ARM as well.
}

variable "key_pair_name" {
  description = "SSH key pair name that should be used to connect with EC2 instance"
  type        = string
}

variable "instance_count" {
  description = "Deployed instances count"
  type        = number
  default     = 1 # Can be any number depending on use case. In this scenario 1 instance is more than enough.
}