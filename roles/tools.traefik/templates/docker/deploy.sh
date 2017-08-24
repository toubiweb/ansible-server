#!/bin/bash

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker-compose --project-name {{ app_name }} -f $BASE_DIR/docker-compose.yml  up -d