#!/bin/bash

yum -y update
yum -y install unzip

cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

AWS_REGION="$(curl http://169.254.169.254/latest/meta-data/placement/region)"
INSTANCE_ID="$(curl http://169.254.169.254/latest/meta-data/instance-id)"

# Get first unallocated EIP with a matching
ALLOCATION_ID="$(aws ec2 describe-addresses --filters "Name=tag-key,Values=${eip_tag}" --output text --query 'Addresses[?AssociationId==null]|[0].AllocationId' --region $AWS_REGION)"

aws ec2 associate-address --instance-id "$INSTANCE_ID" --allocation-id "$ALLOCATION_ID" --region $AWS_REGION
