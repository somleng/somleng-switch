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
      },
      {
        "name": "AHN_CORE_PASSWORD",
        "valueFrom": "${rayo_password_parameter_arn}"
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
    "mountPoints": [
      {
        "containerPath": "${cache_directory}",
        "sourceVolume": "${source_volume}"
      }
    ],
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
      },
      {
        "name": "FS_RECORDINGS_BUCKET_ACCESS_KEY_ID",
        "valueFrom": "${recordings_bucket_access_key_id_parameter_arn}"
      },
      {
        "name": "FS_RECORDINGS_BUCKET_SECRET_ACCESS_KEY",
        "valueFrom": "${recordings_bucket_secret_access_key_parameter_arn}"
      },
      {
        "name": "FS_EVENT_SOCKET_PASSWORD",
        "valueFrom": "${freeswitch_event_socket_password_parameter_arn}"
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
      },
      {
        "containerPort": ${sip_alternative_port},
        "protocol": "udp"
      }
    ],
    "environment": [
      {
        "name": "AWS_DEFAULT_REGION",
        "value": "${region}"
      },
      {
        "name": "FS_CACHE_DIRECTORY",
        "value": "${cache_directory}"
      },
      {
        "name": "FS_STORAGE_DIRECTORY",
        "value": "${cache_directory}/freeswitch/storage"
      },
      {
        "name": "FS_TTS_CACHE_DIRECTORY",
        "value": "${cache_directory}/freeswitch/tts_cache"
      },
      {
        "name": "FS_LOG_DIRECTORY",
        "value": "${cache_directory}/freeswitch/logs"
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
        "name": "FS_EXTERNAL_NAT_INSTANCE_SIP_IP",
        "value": "${external_nat_instance_sip_ip}"
      },
      {
        "name": "FS_EXTERNAL_NAT_INSTANCE_RTP_IP",
        "value": "${external_nat_instance_rtp_ip}"
      },
      {
        "name": "FS_MOD_RAYO_PORT",
        "value": "${rayo_port}"
      },
      {
        "name": "FS_MOD_JSON_CDR_URL",
        "value": "${json_cdr_url}"
      },
      {
        "name": "FS_RECORDINGS_BUCKET_NAME",
        "value": "${recordings_bucket_name}"
      },
      {
        "name": "FS_RECORDINGS_BUCKET_REGION",
        "value": "${recordings_bucket_region}"
      },
      {
        "name": "FS_EVENT_SOCKET_PORT",
        "value": "${freeswitch_event_socket_port}"
      }
    ]
  },
  {
    "name": "freeswitch-event-logger",
    "image": "${freeswitch_event_logger_image}:latest",
    "logConfiguration": {
      "logDriver": "awslogs",
       "options": {
         "awslogs-group": "${freeswitch_event_logger_logs_group}",
         "awslogs-region": "${logs_group_region}",
         "awslogs-stream-prefix": "${app_environment}"
       }
    },
    "startTimeout": 120,
    "essential": false,
    "secrets": [
      {
        "name": "EVENT_SOCKET_PASSWORD",
        "valueFrom": "${freeswitch_event_socket_password_parameter_arn}"
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
        "name": "EVENT_SOCKET_HOST",
        "value": "localhost:${freeswitch_event_socket_port}"
      }
    ]
  }
]
