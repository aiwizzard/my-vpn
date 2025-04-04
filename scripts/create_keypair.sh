#!/bin/bash

# Create an AWS key pair for the VPN server
# Usage: ./create_keypair.sh key_name region

KEY_NAME=${1:-vpn-key}
REGION=${2:-us-east-1}

echo "Creating AWS key pair: $KEY_NAME in region $REGION"

# Create the key pair in AWS
aws ec2 create-key-pair --key-name "$KEY_NAME" --region "$REGION" --query "KeyMaterial" --output text > "$KEY_NAME.pem"

if [ $? -eq 0 ]; then
    # Set the correct permissions on the private key file
    chmod 400 "$KEY_NAME.pem"
    
    echo ""
    echo "Success! Key pair '$KEY_NAME' created and private key saved to $KEY_NAME.pem"
    echo "Be sure to keep this file secure and don't lose it, as you'll need it to access your VPN server."
    echo ""
    echo "Use this key name in your terraform.tfvars file:"
    echo "key_name = \"$KEY_NAME\""
else
    echo "Error creating key pair. Make sure:"
    echo "1. AWS CLI is installed and configured"
    echo "2. You have permissions to create key pairs"
    echo "3. A key pair with this name doesn't already exist"
fi 