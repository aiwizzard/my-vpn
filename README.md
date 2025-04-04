# Personal AWS VPN Server

This project automates the deployment of your own private VPN server on AWS using OpenVPN.

## Overview

This project provides:
- Terraform scripts to create the necessary AWS infrastructure
- Helper scripts to simplify setup and client configuration
- Comprehensive documentation for deployment and operation

## Prerequisites

- AWS account with appropriate permissions
- AWS CLI installed and configured
- Terraform installed (v1.0+)
- SSH key pair for AWS EC2 access (or use our script to create one)

## Quick Start

1. **Clone this repository:**
   ```
   git clone <repository-url>
   cd my-vpn
   ```

2. **Create an AWS key pair** (if you don't already have one):
   ```
   ./scripts/create_keypair.sh your-key-name us-east-1
   ```

3. **Find available subnets** (optional):
   ```
   ./scripts/find_subnets.sh us-east-1
   ```

4. **Configure your deployment:**
   ```
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars to match your needs
   ```

5. **Deploy the infrastructure:**
   ```
   terraform init
   terraform apply
   ```

6. **Connect to your server and complete OpenVPN setup:**
   ```
   ssh -i your-key-name.pem ubuntu@<server-ip>
   sudo ./openvpn-install.sh
   ```

7. **Download your client configuration:**
   ```
   ./scripts/get_client_config.sh ubuntu@<server-ip> client-name
   ```

8. **Set up an OpenVPN client** on your device and import the configuration file.

## Detailed Documentation

See the `docs/` directory for detailed guides:
- [Usage Guide](docs/usage_guide.md): Complete setup and usage instructions

## Common Issues

### No Public IP Address
If your instance doesn't have a public IP address, rebuild the infrastructure:

1. First, destroy the current resources:
   ```
   cd terraform
   terraform destroy
   ```

2. The updated configurations will automatically:
   - Associate a public IP address with your instance
   - Configure proper routing for internet access
   - Set up the necessary subnet configurations

3. Deploy again:
   ```
   terraform apply
   ```

4. Verify the public IP:
   ```
   terraform output vpn_server_public_ip
   ```

### No Subnets Found
If your AWS account doesn't have a default VPC with subnets, this project will:

1. Use your specified subnet (if you provided one in terraform.tfvars)
2. OR create a new subnet automatically in your default VPC if none exists

You can still manually specify a subnet if you prefer:
1. Run the subnet finder script: `./scripts/find_subnets.sh`
2. Add the subnet_id to your terraform.tfvars file:
   ```
   subnet_id = "subnet-xxxxxxxxxxxx"
   ```

### Invalid CIDR Block
Make sure you specify CIDR notation for IP addresses:
- Correct: `"192.168.1.35/32"` (for a single IP)
- Incorrect: `"192.168.1.35"` (missing subnet mask)

## Security Considerations

- This VPN server is accessible from the internet (required for VPN functionality)
- Only necessary ports are opened in the security group (SSH and OpenVPN)
- Automated updates are enabled for security patches
- Change the default `allowed_ssh_cidr` in terraform.tfvars to restrict SSH access to your IP address only

## Maintenance

To update the OpenVPN software:
1. SSH into your server
2. Run `sudo apt-get update && sudo apt-get upgrade -y`

To add additional clients:
1. SSH into your server
2. Run `sudo ./openvpn-install.sh`
3. Select the option to add a new client

## Troubleshooting

### SSH Connection Timed Out

If you get "Operation timed out" when trying to SSH to your server:

1. **Verify the security group is correctly configured**:
   - Check AWS Console → EC2 → Security Groups
   - Ensure port 22 is open in the inbound rules

2. **Check instance status**:
   - Verify the instance is running in AWS Console
   - Check the instance's "Status Checks" are passing

3. **Check network configuration**:
   - Confirm the subnet has internet access
   - Verify the route table has a route to the internet gateway
   - Check that the instance has a public IP address

4. **Troubleshoot with temporary open security group**:
   - Temporarily update `allowed_ssh_cidr` to `"0.0.0.0/0"` in terraform.tfvars
   - Run `terraform apply` to update settings
   - Try connecting again
   - **IMPORTANT**: Remember to restrict access after troubleshooting

5. **Verify SSH key**:
   - Make sure permissions are correct: `chmod 400 your-key-name.pem`
   - Try verbose output: `ssh -v -i your-key-name.pem ubuntu@your-ip`

6. **Check for AWS regional issues**:
   - Look at AWS Service Health Dashboard for any reported issues

### No Public IP Address
If your instance doesn't have a public IP address, rebuild the infrastructure:

1. First, destroy the current resources:
   ```
   cd terraform
   terraform destroy
   ```

2. The updated configurations will automatically:
   - Associate a public IP address with your instance
   - Configure proper routing for internet access
   - Set up the necessary subnet configurations

3. Deploy again:
   ```
   terraform apply
   ```

4. Verify the public IP:
   ```
   terraform output vpn_server_public_ip
   ```

## Additional Information

After deploying your VPN server with Terraform, you can get the IPv4 address in several ways:

1. **From Terraform output:**
   After running `terraform apply`, the IPv4 address is shown in the output as `vpn_server_public_ip`

2. **Using Terraform command:**
   ```
   cd terraform
   terraform output vpn_server_public_ip
   ```

3. **From AWS Console:**
   - Log in to AWS Console
   - Go to EC2 service
   - Find your instance named "OpenVPN-Server"
   - Copy the Public IPv4 address from the instance details

4. **Using AWS CLI:**
   ```
   aws ec2 describe-instances --filters "Name=tag:Name,Values=OpenVPN-Server" --query "Reservations[].Instances[].PublicIpAddress" --output text
   ```

You'll need this IPv4 address to:
- SSH into your server: `ssh -i your-key-name.pem ubuntu@<IPv4-address>`
- Download client configs: `./scripts/get_client_config.sh ubuntu@<IPv4-address> client-name` 