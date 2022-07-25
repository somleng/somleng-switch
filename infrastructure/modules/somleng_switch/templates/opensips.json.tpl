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
    "mountPoints": [
      {
        "sourceVolume": "opensips",
        "containerPath": "/var/opensips"
      }
    ],
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
      }
    ]
  },
  {
    "name": "opensips_scheduler",
    "image": "${opensips_scheduler_image}:latest",
    "logConfiguration": {
      "logDriver": "awslogs",
       "options": {
         "awslogs-group": "${opensips_scheduler_logs_group}",
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
    "environment": [
      {
        "name": "FIFO_NAME",
        "value": "/var/opensips/opensips_fifo"
      }
    ],
    "essential": true
  }
]
