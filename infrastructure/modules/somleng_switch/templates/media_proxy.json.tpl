[
  {
    "name": "media_proxy",
    "image": "${media_proxy_image}:latest",
    "logConfiguration": {
      "logDriver": "awslogs",
       "options": {
         "awslogs-group": "${logs_group}",
         "awslogs-region": "${logs_group_region}",
         "awslogs-stream-prefix": "${app_environment}"
       }
    },
    "essential": true,
    "environment": [
      {
        "name": "NG_PORT",
        "value": "${ng_port}"
      },
      {
        "name": "MEDIA_PORT_MIN",
        "value": "${media_port_min}"
      },
      {
        "name": "MEDIA_PORT_MAX",
        "value": "${media_port_max}"
      }
    ]
  }
]
