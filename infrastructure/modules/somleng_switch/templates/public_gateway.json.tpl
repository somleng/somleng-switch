[
  {
    "name": "public_gateway",
    "image": "${public_gateway_image}:latest",
    "logConfiguration": {
      "logDriver": "awslogs",
       "options": {
         "awslogs-group": "${logs_group}",
         "awslogs-region": "${logs_group_region}",
         "awslogs-stream-prefix": "${app_environment}"
       }
    },
    "mountPoints": [
      {
        "sourceVolume": "opensips",
        "containerPath": "/var/opensips"
      }
    ],
    "essential": true,
    "portMappings": [
      {
        "containerPort": ${sip_port},
        "protocol": "udp"
      },
      {
        "containerPort": ${sip_alternative_port},
        "protocol": "udp"
      }
    ],
    "secrets": [
      {
        "name": "DATABASE_PASSWORD",
        "valueFrom": "${database_password_parameter_arn}"
      }
    ],
    "environment": [
      {
        "name": "FIFO_NAME",
        "value": "/var/opensips/opensips_fifo"
      },
      {
        "name": "DATABASE_NAME",
        "value": "${database_name}"
      },
      {
        "name": "DATABASE_USERNAME",
        "value": "${database_username}"
      },
      {
        "name": "DATABASE_HOST",
        "value": "${database_host}"
      },
      {
        "name": "DATABASE_PORT",
        "value": "${database_port}"
      },
      {
        "name": "SIP_PORT",
        "value": "${sip_port}"
      },
      {
        "name": "SIP_ALTERNATIVE_PORT",
        "value": "${sip_alternative_port}"
      },
      {
        "name": "SIP_ADVERTISED_IP",
        "value": "${sip_advertised_ip}"
      }
    ]
  },
  {
    "name": "opensips_scheduler",
    "image": "${opensips_scheduler_image}:latest",
    "mountPoints": [
      {
        "sourceVolume": "opensips",
        "containerPath": "/var/opensips"
      }
    ],
    "environment": [
      {
        "name": "FIFO_NAME",
        "value": "/var/opensips/opensips_fifo"
      },
      {
        "name": "MI_COMMANDS",
        "value": "lb_reload,address_reload"
      }
    ],
    "essential": true
  }
]
