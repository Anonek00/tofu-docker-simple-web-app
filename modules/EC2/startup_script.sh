#!/bin/bash
# This script launches upon system first start

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

#Prepare infra for docker-compose

#Application directory
sudo mkdir -p /opt/node-composed

# Dedicated service user for nodeapp
sudo useradd -m -s /bin/bash nodeapp

# Adding user to docker group to enable docker/docker-compose for this user
sudo usermod -aG docker nodeapp

# Permissions update for app directory
sudo chown -R nodeapp:nodeapp /opt/node-composed
sudo chmod -R 755 /opt/node-composed


echo "Init script finished!" > /var/log/user-data.log
