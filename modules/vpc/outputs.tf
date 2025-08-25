# Info that Tofu should display after successful config deployment
output "vpc_id" {
  description = "ID of created VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnets IDs"
  value       = aws_subnet.public[*].id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}
