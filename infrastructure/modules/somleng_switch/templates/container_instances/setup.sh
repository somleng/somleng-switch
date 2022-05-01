#!/bin/bash

systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# ECS config
{
  echo "ECS_CLUSTER=${cluster_name}"
} >> /etc/ecs/ecs.config

start ecs

echo "Done"
