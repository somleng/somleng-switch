[
  {
    "name": "opensips",
    "image": "${app_image}:latest",
    "logConfiguration": {
      "logDriver": "awslogs",
       "options": {
         "awslogs-group": "${opensips_logs_group}",
         "awslogs-region": "${logs_group_region}",
         "awslogs-stream-prefix": "${app_environment}"
       }
    },
    "essential": true,
    "portMappings": [
      {
        "containerPort": 5060,
        "protocol": "udp"
      },
      {
        "containerPort": 5080,
        "protocol": "udp"
      }
    ],
    "secrets": [
      {
        "name": "DATABASE_PASSWORD",
        "valueFrom": "${database_password_parameter_arn}"
      },
      {
        "name": "EVENT_SOCKET_PASSWORD",
        "valueFrom": "${freeswitch_event_socket_password_parameter_arn}"
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
      }
    ]
  }
]
