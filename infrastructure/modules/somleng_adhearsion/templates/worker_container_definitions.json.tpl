[
  {
    "name": "worker",
    "image": "${app_image}:latest",
    "logConfiguration": {
      "logDriver": "awslogs",
       "options": {
         "awslogs-group": "${worker_logs_group}",
         "awslogs-region": "${logs_group_region}",
         "awslogs-stream-prefix": "${app_environment}"
       }
    },
    "command": ["bundle", "exec", "shoryuken", "-C", "config/shoryuken.yml"],
    "essential": true,
    "secrets": [
      {
        "name": "APP_MASTER_KEY",
        "valueFrom": "${application_master_key_parameter_arn}"
      }
    ],
    "environment": [
      {
        "name": "AHN_ENV",
        "value": "${app_environment}"
      },
      {
        "name": "APP_ENV",
        "value": "${app_environment}"
      }
    ]
  }
]
