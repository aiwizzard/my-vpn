# OpenVPN AWS Deployment Guide

This guide explains how to deploy, configure, and use your private OpenVPN server on AWS.

## Deployment

1. **Prepare AWS credentials**:
   - Ensure you have AWS access and secret keys with appropriate permissions
   - Run `aws configure` to set up your credentials

2. **Prepare SSH key pair**:
   - Make sure you have an SSH key pair in your AWS region
   - If not, create one through the AWS Console or AWS CLI

3. **Configure Terraform variables**:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your preferred settings
   ```

4. **Deploy the infrastructure**:
   ```bash
   terraform init
   terraform plan  # Review changes
   terraform apply # Confirm with 'yes' to deploy
   ```

5. **Note the outputs**:
   - The server's public IP address
   - SSH command to connect to the server

## Initial VPN Setup

1. **SSH into your server**:
   ```bash
   ssh -i your-key.pem ubuntu@your-server-ip
   ```

2. **Run the OpenVPN installer script**:
   ```bash
   curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
   chmod +x openvpn-install.sh
   sudo ./openvpn-install.sh
   ```

3. **Follow the interactive setup**:
   - Accept defaults or customize as needed
   - Name your first client (e.g., "my-laptop")
   - The script will create a .ovpn file in your home directory

## Adding More Clients

To add more clients (devices):

1. **Run the installer script again**:
   ```bash
   sudo ./openvpn-install.sh
   ```

2. **Select option to add a new client**
   - Provide a unique name for the client (e.g., "my-phone")
   - The script will generate another .ovpn file

## Downloading Client Configurations

1. **From your local machine**:
   ```bash
   ./scripts/get_client_config.sh ubuntu@your-server-ip client-name /path/to/my-vpn-aws-key.pem
   ```

2. **The configuration will be saved to**:
   ```
   ./client-configs/client-name.ovpn
   ```

## Using the VPN

1. **Install an OpenVPN client**:
   - Windows: [OpenVPN Connect](https://openvpn.net/client/)
   - macOS: [Tunnelblick](https://tunnelblick.net/) or [OpenVPN Connect](https://openvpn.net/client/)
   - iOS/Android: OpenVPN Connect from the app store

2. **Import the .ovpn configuration file** into your client application

3. **Connect to your VPN**:
   - You should now be able to connect to your private VPN
   - Your internet traffic will be routed through your AWS server

## Troubleshooting

- **Connection issues**: Check AWS security groups to ensure UDP port 1194 is open
- **Client problems**: Try regenerating the client configuration
- **Server issues**: Check the OpenVPN service status with `sudo systemctl status openvpn` 