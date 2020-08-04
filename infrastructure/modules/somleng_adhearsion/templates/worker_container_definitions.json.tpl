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
    "environment": [
      {
        "name": "AHN_ENV",
        "value": "${app_environment}"
      }
    ]
  }
]
