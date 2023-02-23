[
  {
    "name": "nginx",
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
        "containerPort": 80
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
        "containerPort": 3000
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
        "value": "3000"
      },
      {
        "name": "AHN_CORE_PORT",
        "value": "5222"
      },
      {
        "name": "SERVICES_FUNCTION_ARN",
        "value": "${services_function_arn}"
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
      "command": ["CMD-SHELL", "fs_cli -p $FS_EVENT_SOCKET_PASSWORD -x 'rayo status' | rayo_status_parser"],
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
      },
      {
        "name": "AWS_ACCESS_KEY_ID",
        "valueFrom": "${fs_modules_access_key_id_parameter_arn}"
      },
      {
        "name": "AWS_SECRET_ACCESS_KEY",
        "valueFrom": "${fs_modules_secret_access_key_parameter_arn}"
      }
    ],
    "portMappings": [
      {
        "containerPort": 5222,
        "protocol": "tcp"
      },
      {
        "containerPort": ${sip_port},
        "protocol": "udp"
      },
      {
        "containerPort": ${sip_alternative_port},
        "protocol": "udp"
      },
      {
        "containerPort": 8021,
        "protocol": "tcp"
      }
    ],
    "environment": [
      {
        "name": "AWS_DEFAULT_REGION",
        "value": "${region}"
      },
      {
        "name": "AWS_TRANSCRIBE_REGION",
        "value": "${aws_transcribe_region}"
      },
      {
        "name": "AWS_REGION",
        "value": "${aws_transcribe_region}"
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
        "name": "FS_EXTERNAL_RTP_IP",
        "value": "${external_rtp_ip}"
      },
      {
        "name": "FS_ALTERNATIVE_SIP_OUTBOUND_IP",
        "value": "${alternative_sip_outbound_ip}"
      },
      {
        "name": "FS_ALTERNATIVE_RTP_IP",
        "value": "${alternative_rtp_ip}"
      },
      {
        "name": "FS_MOD_RAYO_PORT",
        "value": "5222"
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
      },
      {
        "name": "FS_SIP_PORT",
        "value": "${sip_port}"
      },
      {
        "name": "FS_SIP_ALTERNATIVE_PORT",
        "value": "${sip_alternative_port}"
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
