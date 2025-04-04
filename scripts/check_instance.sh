#!/bin/bash

# Check EC2 instance status and security group settings
# Usage: ./check_instance.sh instance-id [region]

INSTANCE_ID=${1}
REGION=${2:-us-east-1}

if [[ -z "$INSTANCE_ID" ]]; then
  echo "Usage: $0 instance-id [region]"
  echo "Example: $0 i-0123456789abcdef0 us-east-1"
  echo ""
  echo "You can get the instance ID from: "
  echo "- AWS Console"
  echo "- Terraform output: terraform state show aws_instance.vpn_server | grep \"id\""
  exit 1
fi

echo "Checking instance $INSTANCE_ID in region $REGION"
echo "------------------------------------------------"

# Check instance status
echo "Instance Status:"
aws ec2 describe-instance-status --instance-ids "$INSTANCE_ID" --region "$REGION" --query "InstanceStatuses[0]" --output yaml

echo ""
echo "Instance Details:"
aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --region "$REGION" --query "Reservations[0].Instances[0].{InstanceId:InstanceId,State:State.Name,PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress,SubnetId:SubnetId,VpcId:VpcId,SecurityGroups:SecurityGroups}" --output yaml

# Check security group rules
echo ""
echo "Security Group Rules:"
SECURITY_GROUP_ID=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --region "$REGION" --query "Reservations[0].Instances[0].SecurityGroups[0].GroupId" --output text)
aws ec2 describe-security-groups --group-ids "$SECURITY_GROUP_ID" --region "$REGION" --query "SecurityGroups[0].{GroupId:GroupId,IngressRules:IpPermissions,EgressRules:IpPermissionsEgress}" --output yaml

# Check network ACLs
echo ""
echo "Network ACLs:"
SUBNET_ID=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --region "$REGION" --query "Reservations[0].Instances[0].SubnetId" --output text)
NACL_ID=$(aws ec2 describe-network-acls --region "$REGION" --filters "Name=association.subnet-id,Values=$SUBNET_ID" --query "NetworkAcls[0].NetworkAclId" --output text)
aws ec2 describe-network-acls --network-acl-ids "$NACL_ID" --region "$REGION" --query "NetworkAcls[0].{NetworkAclId:NetworkAclId,IngressRules:Entries[?Egress==\`false\`],EgressRules:Entries[?Egress==\`true\`]}" --output yaml

echo ""
echo "Connectivity Check:"
echo "1. Try SSH: ssh -v -i your-key.pem ubuntu@$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --region "$REGION" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)"
echo "2. Check if ports are reachable using: nc -zv $(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --region "$REGION" --query "Reservations[0].Instances[0].PublicIpAddress" --output text) 22" 