#!/bin/bash

NOW=`date +%Y-%m-%d-%H-%M-%S`

# suffix access.log & error.log with current date/time
find {{ app_www_dir }} -name nginx.access.log -exec mv {} {}.${NOW} \;
find {{ app_www_dir }} -name nginx.error.log -exec mv {} {}.${NOW} \;

# reload nginx to recreate logs files
docker exec {{ app_name }} bash -c "nginx -s reload"
