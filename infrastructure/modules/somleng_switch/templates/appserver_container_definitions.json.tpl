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
    "dependsOn": [
      {
        "containerName": "freeswitch",
        "condition": "HEALTHY"
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
        "name": "AHN_CORE_PORT",
        "value": "${rayo_port}"
      }
    ]
  },
  {
    "name": "freeswitch",
    "image": "${freeswitch_image}:latest",
    "logConfiguration": {
      "logDriver": "awslogs",
       "options": {
         "awslogs-group": "${freeswitch_logs_group}",
         "awslogs-region": "${logs_group_region}",
         "awslogs-stream-prefix": "${app_environment}"
       }
    },
    "startTimeout": 120,
    "healthCheck": {
      "command": [ "CMD-SHELL", "nc -z -w 5 localhost ${rayo_port}" ],
      "interval": 10,
      "retries": 10,
      "timeout": 5
    },
    "essential": true,
    "secrets": [
      {
        "name": "FS_DATABASE_PASSWORD",
        "valueFrom": "${database_password_parameter_arn}"
      },
      {
        "name": "FS_MOD_RAYO_PASSWORD",
        "valueFrom": "${rayo_password_parameter_arn}"
      },
      {
        "name": "FS_MOD_JSON_CDR_PASSWORD",
        "valueFrom": "${json_cdr_password_parameter_arn}"
      }
    ],
    "portMappings": [
      {
        "containerPort": ${rayo_port},
        "protocol": "tcp"
      },
      {
        "containerPort": ${sip_port},
        "protocol": "udp"
      }
    ],
    "environment": [
      {
        "name": "AWS_DEFAULT_REGION",
        "value": "${region}"
      },
      {
        "name": "FS_DATABASE_NAME",
        "value": "${database_name}"
      },
      {
        "name": "FS_DATABASE_USERNAME",
        "value": "${database_username}"
      },
      {
        "name": "FS_DATABASE_HOST",
        "value": "${database_host}"
      },
      {
        "name": "FS_DATABASE_PORT",
        "value": "${database_port}"
      },
      {
        "name": "FS_EXTERNAL_SIP_IP",
        "value": "${external_sip_ip}"
      },
      {
        "name": "FS_EXTERNAL_RTP_IP",
        "value": "${external_rtp_ip}"
      },
      {
        "name": "FS_MOD_RAYO_PORT",
        "value": "${rayo_port}"
      },
      {
        "name": "FS_MOD_JSON_CDR_URL",
        "value": "${json_cdr_url}"
      }
    ]
  }
]
