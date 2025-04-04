#!/bin/bash

# Find available subnets in AWS
# Usage: ./find_subnets.sh [region]

REGION=${1:-us-east-1}

echo "Finding available subnets in region: $REGION"
echo "--------------------------------------------"

# Get default VPC ID
DEFAULT_VPC=$(aws ec2 describe-vpcs --region "$REGION" --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text)

if [[ "$DEFAULT_VPC" == "None" || -z "$DEFAULT_VPC" ]]; then
  echo "No default VPC found in region $REGION."
  echo "Listing all VPCs instead:"
  aws ec2 describe-vpcs --region "$REGION" --query "Vpcs[*].[VpcId,CidrBlock,IsDefault]" --output table
else
  echo "Default VPC: $DEFAULT_VPC"
  
  # List subnets in the default VPC
  echo "Subnets in default VPC:"
  aws ec2 describe-subnets --region "$REGION" --filters "Name=vpc-id,Values=$DEFAULT_VPC" \
    --query "Subnets[*].[SubnetId,AvailabilityZone,CidrBlock,AvailableIpAddressCount]" \
    --output table
fi

echo ""
echo "To use a specific subnet, add this to your terraform.tfvars file:"
echo "subnet_id = \"subnet-xxxxxxxxxxxx\"  # Replace with your subnet ID" 