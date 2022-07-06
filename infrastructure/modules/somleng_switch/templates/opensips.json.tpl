[
  {
    "name": "opensips",
    "image": "${opensips_image}:latest",
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
        "containerPort": ${sip_port},
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
        "name": "EVENT_SOCKET_HOST",
        "value": "localhost:${freeswitch_event_socket_port}"
      }
    ]
  }
]
