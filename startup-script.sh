#!/bin/bash
# Install NGINX
sudo apt-get update
sudo apt-get install -y nginx

# Optional: Configure NGINX to serve your application or proxy requests
# For a basic setup, we will ensure NGINX is running
sudo systemctl enable nginx
sudo systemctl start nginx
