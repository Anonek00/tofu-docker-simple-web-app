variable "vpc_id" {
  description = "VPC ID for which security group is created"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "IP allowed to SSH into EC2 instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # 0.0.0.0/0 means that SSH is possible from anywhere. This should be set to office public IP.
}

variable "allowed_inbound_cidrs" {
  description = "IP allowed to SSH into EC2 instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # 0.0.0.0/0 means that traffic is accepted from anywhere. This should be set to office public IP.
}