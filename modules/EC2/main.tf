# Latest Amazon Linux
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# EC2 instances
resource "aws_instance" "web" {
  count = var.instance_count

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name              = var.key_pair_name
  subnet_id             = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids = var.security_group_ids

  # Startup script
  user_data_base64 = base64encode(templatefile("${path.module}/startup_script.sh", {
    environment = var.environment
  }))

  # Additional storage (optional)
  root_block_device {
    volume_type = "gp2"
    volume_size = 8  # Free tier to 30GB
    encrypted   = true
  }

  tags = {
    Name        = "${var.environment}-web-${count.index + 1}"
    Environment = var.environment
    Type        = "Web Server"
  }
}