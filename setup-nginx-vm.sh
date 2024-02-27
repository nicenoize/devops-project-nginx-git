#!/bin/bash

# Set variables
PRIVATE_KEY_PATH="/Users/seebo/.ssh/devops"
PUBLIC_KEY_PATH="/Users/seebo/.ssh/devopspub"
TERRAFORM_DIR="/Users/seebo/Documents/Uni/DevOps/Allocate-a-virtual-machine-in-the-cloud"
INSTANCE_USERNAME="devOps"

# Initialize Terraform
echo "Initializing Terraform..."
cd "$TERRAFORM_DIR" || exit
terraform init

# Apply Terraform configuration
echo "Applying Terraform configuration..."
terraform apply -auto-approve

# Get the public IP of the instance
INSTANCE_IP=$(terraform output -raw instanceIPv4)
echo "Instance IP Address: $INSTANCE_IP"

# Wait a bit for the instance to start up (optional)
echo "Waiting for instance to start up..."
sleep 30

# Commands to setup Nginx
SETUP_COMMANDS=$(cat <<EOF
sudo apt update
sudo apt install -y nginx
sudo tee /etc/nginx/sites-available/default <<'EOL'
server {
    listen 80; # Listen on port 80 for IPv4 requests
    listen [::]:80; # Listen on port 80 for IPv6 requests

    server_name _;

    location / {
        proxy_pass http://34.118.108.122;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /api {
        rewrite ^/api/(.*)\$ /\$1 break;
        proxy_pass http://34.118.54.55:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL
sudo nginx -t
sudo systemctl restart nginx
EOF
)

# SSH into the instance and execute the setup commands
echo "Connecting to the instance via SSH to setup Nginx..."
ssh -i "$PRIVATE_KEY_PATH" -o "StrictHostKeyChecking=no" "$INSTANCE_USERNAME@$INSTANCE_IP" "$SETUP_COMMANDS"

echo "Nginx setup complete. You can now access your server."

# After SSH session is closed, you may want to keep the instance running, so remove the terraform destroy command
# echo "Destroying Terraform-managed infrastructure..."
# terraform destroy -auto-approve
