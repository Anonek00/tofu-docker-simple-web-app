output "instance_ids" {
  description = "EC2 instance ID"
  value       = aws_instance.web[*].id
}

output "public_ips" {
  description = "EC2 instance public IP"
  value       = aws_instance.web[*].public_ip
}

output "private_ips" {
  description = "EC2 instance private IP"
  value       = aws_instance.web[*].private_ip
}

output "public_dns" {
  description = "EC2 instance public DNS name"
  value       = aws_instance.web[*].public_dns
}