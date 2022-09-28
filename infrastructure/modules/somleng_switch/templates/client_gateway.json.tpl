[
  {
    "name": "client_gateway",
    "image": "${client_gateway_image}:latest",
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
        "hostPort" : ${sip_port},
        "containerPort": ${sip_port},
        "protocol": "udp"
      },
      {
        "hostPort" : ${sip_port},
        "containerPort": ${sip_port},
        "protocol": "tcp"
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
        "value": "lb_reload,domain_reload,rtpengine_reload"
      }
    ],
    "essential": true
  }
]
