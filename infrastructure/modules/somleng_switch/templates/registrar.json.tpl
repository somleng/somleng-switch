[
  {
    "name": "registrar",
    "image": "${registrar_image}:latest",
    "logConfiguration": {
      "logDriver": "awslogs",
       "options": {
         "awslogs-group": "${registrar_logs_group}",
         "awslogs-region": "${logs_group_region}",
         "awslogs-stream-prefix": "${app_environment}"
       }
    },
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
  }
]
