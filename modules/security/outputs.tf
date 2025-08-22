output "web_security_group_id" {
  description = "Security group ID for EC2 Web App instance"
  value       = aws_security_group.web.id
}