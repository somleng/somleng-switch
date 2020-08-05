[
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
      },
      {
        "name": "AWS_SQS_DEFAULT_QUEUE_NAME",
        "value": "${aws_sqs_default_queue_name}"
      },
      {
        "name": "AWS_DEFAULT_REGION",
        "value": "${region}"
      }
    ]
  }
]
