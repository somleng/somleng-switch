#!/bin/bash

systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# ECS config
cat <<'EOF' >> /etc/ecs/ecs.config
ECS_CLUSTER=${cluster_name}
ECS_RESERVED_MEMORY=128
EOF

start ecs

echo "Done"
