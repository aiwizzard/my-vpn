provider "aws" {
  region = var.aws_region
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get subnets for the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get the default internet gateway
data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Create subnet if no subnet is provided and default VPC has no subnets
resource "aws_subnet" "vpn_subnet" {
  count                   = var.subnet_id == "" && length(data.aws_subnets.default.ids) == 0 ? 1 : 0
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.100.0/24"  # Choose a CIDR that doesn't conflict with existing subnets
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true  # This allows instances to get public IPs by default
  
  tags = {
    Name = "vpn-subnet"
  }
}

# Create a route table for our subnet
resource "aws_route_table" "vpn_route_table" {
  count  = var.subnet_id == "" && length(data.aws_subnets.default.ids) == 0 ? 1 : 0
  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.default.id
  }

  tags = {
    Name = "vpn-route-table"
  }
}

# Associate the route table with the subnet
resource "aws_route_table_association" "vpn_route_assoc" {
  count          = var.subnet_id == "" && length(data.aws_subnets.default.ids) == 0 ? 1 : 0
  subnet_id      = aws_subnet.vpn_subnet[0].id
  route_table_id = aws_route_table.vpn_route_table[0].id
}

locals {
  subnet_id = var.subnet_id != "" ? var.subnet_id : (
    length(data.aws_subnets.default.ids) > 0 ? tolist(data.aws_subnets.default.ids)[0] : aws_subnet.vpn_subnet[0].id
  )
}

resource "aws_instance" "vpn_server" {
  ami                         = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.vpn_sg.id]
  subnet_id                   = local.subnet_id
  associate_public_ip_address = true
  
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get upgrade -y
              apt-get install -y git curl wget
              curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
              chmod +x openvpn-install.sh
              EOF

  tags = {
    Name = "OpenVPN-Server"
  }

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }

  # Ensure all subnet infrastructure is ready before creating the instance
  depends_on = [
    aws_subnet.vpn_subnet,
    aws_route_table_association.vpn_route_assoc
  ]
}

resource "aws_security_group" "vpn_sg" {
  name        = "vpn-security-group"
  description = "Security group for OpenVPN server"

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from anywhere temporarily
    description = "SSH access"
  }

  # OpenVPN access
  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "OpenVPN access"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "OpenVPN-SG"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

output "vpn_server_public_ip" {
  value = aws_instance.vpn_server.public_ip
}

output "ssh_command" {
  value = "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.vpn_server.public_ip}"
}

output "openvpn_setup_command" {
  value = "sudo ./openvpn-install.sh"
} 