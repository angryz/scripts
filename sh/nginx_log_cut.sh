#!/bin/sh

############################################################
# Cut Nginx log evertyday and delete very old history log (30 days before).
# To make this work, add crontab task, for example:
# 0 0 * * * /usr/local/nginx/sbin/cut_log.sh >>/usr/local/nginx/logs/cut_log.out 2>&1 &
# Author: zzp
# Created at: 2015/11/5
############################################################

nginx_path="/usr/local/nginx"
logs_path="${nginx_path}/logs"
suffix=`date -d "yesterday" +"%Y%m%d"`
DAYS=30

for logfile in `find $logs_path -name "*access.log" -type f`; do
  mv $logfile ${logfile}.$suffix
done;

$nginx_path/sbin/nginx -s reload

find ${logs_path} -name "*access.log*" -type f -mtime +$DAYS -exec rm {} \;
