[
  {
    "name": "${webserver_container_name}",
    "image": "${nginx_image}:latest",
    "logConfiguration": {
      "logDriver": "awslogs",
       "options": {
         "awslogs-group": "${nginx_logs_group}",
         "awslogs-region": "${logs_group_region}",
         "awslogs-stream-prefix": "${app_environment}"
       }
    },
    "essential": true,
    "portMappings": [
      {
        "containerPort": ${webserver_container_port}
      }
    ],
    "dependsOn": [
      {
        "containerName": "app",
        "condition": "HEALTHY"
      }
    ]
  },
  {
    "name": "app",
    "image": "${app_image}:latest",
    "logConfiguration": {
      "logDriver": "awslogs",
       "options": {
         "awslogs-group": "${app_logs_group}",
         "awslogs-region": "${logs_group_region}",
         "awslogs-stream-prefix": "${app_environment}"
       }
    },
    "startTimeout": 120,
    "healthCheck": {
      "command": [ "CMD-SHELL", "wget --server-response --spider --quiet http://localhost:3000/health_checks 2>&1 | grep '200 OK' > /dev/null" ],
      "interval": 10,
      "retries": 10,
      "timeout": 5
    },
    "essential": true,
    "secrets": [
      {
        "name": "APP_MASTER_KEY",
        "valueFrom": "${application_master_key_parameter_arn}"
      }
    ],
    "portMappings": [
      {
        "containerPort": ${app_port}
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
      },
      {
        "name": "RACK_ENV",
        "value": "${app_environment}"
      },
      {
        "name": "AWS_DEFAULT_REGION",
        "value": "${region}"
      },
      {
        "name": "AHN_CORE_HTTP_PORT",
        "value": "${app_port}"
      },
      {
        "name": "AHN_CORE_HOST",
        "value": "${ahn_core_host}"
      }
    ]
  }
]
