# Security Module description

This module creates a security group for web application EC2 instances, defining inbound rules for HTTP, HTTPS, SSH, and application-specific ports (80,443), and allowing all outbound traffic. It supports environment-based tagging and outputs the security group ID for use in other resources.