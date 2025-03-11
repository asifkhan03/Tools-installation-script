#!/bin/bash
set -e  # Exit on error

# Update package list
sudo apt update -y

# Install necessary dependencies
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add Docker repository
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Update package list again
sudo apt update -y

# Verify available Docker versions
apt-cache policy docker-ce

# Install Docker
sudo apt install -y docker-ce

# Ensure Docker service is running
sudo systemctl enable --now docker

# Adjust permissions for Docker socket (optional)
sudo chmod 666 /var/run/docker.sock

# Verify Docker installation
docker --version
