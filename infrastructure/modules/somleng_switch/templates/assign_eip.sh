#!/bin/bash

yum -y update
yum -y install unzip

cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

AWS_REGION="$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)"
INSTANCE_ID="$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)"

# Get first unallocated EIP with a matching tag sorted by the Priority tag
ALLOCATION_ID="$(aws ec2 describe-addresses --filters "Name=tag-key,Values=${eip_tag}" --output text --query 'Addresses[?AssociationId==null].[AllocationId,Tags[?Key==`Priority`].Value|[0]]|sort_by(@, &[1])|[0][0]' --region $AWS_REGION)"

aws ec2 associate-address --instance-id "$INSTANCE_ID" --allocation-id "$ALLOCATION_ID" --region $AWS_REGION
