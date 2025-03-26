#! /bin/bash

# Add the Ansible PPA (Personal Package Archive) to the system
sudo apt-add-repository ppa:ansible/ansible -y

# Update the package list
sudo apt update -y 

# Install Ansible
sudo apt install ansible -y
