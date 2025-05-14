#!/usr/bin/env bash

echo "Cleaning up /var/log/syslog"
> /var/log/syslog   &\
> /var/log/syslog.1 &\
> /var/log/syslog.2


echo "Cleaning up /var/log/nginx/error.log"
> /var/log/nginx/error.log &
> /var/log/nginx/error.log.1

echo "Find the master process and kill it"
ps -axfo pid,ppid,uname,cmd | grep nginx | grep -v '\\_' | awk '{print $1}' | xargs kill -9

echo "Wait 10 seconds"
sleep 10

while true; do
    echo "Attempting to start nginx"
    /etc/rc.d/rc.nginx start
    sleep 10
    echo "Check nginx status"
    /etc/rc.d/rc.nginx status | grep "is running" && echo "nginx is running"; exit 0
done
