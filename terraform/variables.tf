variable "aws_region" {
  description = "AWS region to deploy the VPN server"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair to use for the EC2 instance"
  type        = string
}

variable "ami_id" {
  description = "Custom AMI ID to use (if left empty, latest Ubuntu 22.04 will be used)"
  type        = string
  default     = ""
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to the instance (e.g., your IP address)"
  type        = string
  default     = "0.0.0.0/0"  # IMPORTANT: Change this to your IP for security reasons
}

variable "subnet_id" {
  description = "Subnet ID to deploy the EC2 instance (if left empty, first subnet in default VPC will be used)"
  type        = string
  default     = ""
} 