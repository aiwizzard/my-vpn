#!/bin/bash

# Usage: ./get_client_config.sh user@vpn-server-ip client_name ssh_key_path

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 user@vpn-server-ip client_name [ssh_key_path]"
    echo "Example: $0 ubuntu@1.2.3.4 my-laptop ~/my-key.pem"
    exit 1
fi

SERVER=$1
CLIENT_NAME=$2
SSH_KEY=""

if [ "$#" -ge 3 ]; then
    SSH_KEY="-i $3"
fi

# Create a local directory for configs if it doesn't exist
mkdir -p ./client-configs

# Download the client configuration file
echo "Downloading OpenVPN client configuration for $CLIENT_NAME..."
scp $SSH_KEY "$SERVER:/home/ubuntu/$CLIENT_NAME.ovpn" ./client-configs/

if [ $? -eq 0 ]; then
    echo ""
    echo "Success! Client configuration downloaded to ./client-configs/$CLIENT_NAME.ovpn"
    echo ""
    echo "To use this configuration:"
    echo "1. Install an OpenVPN client on your device"
    echo "2. Import the .ovpn file into your OpenVPN client"
    echo "3. Connect to your private VPN"
else
    echo "Error downloading client configuration. Make sure:"
    echo "1. The client name is correct"
    echo "2. SSH access to the server is working (did you specify the key file with the third parameter?)"
    echo "3. The client config was generated on the server"
fi 