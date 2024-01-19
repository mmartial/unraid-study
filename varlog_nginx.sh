#!/usr/bin/env bash

echo "Cleaning up /var/log/syslog then restarting the syslog daemon"
> /var/log/syslog   &\
> /var/log/syslog.1 &\
> /var/log/syslog.2
/etc/rc.d/rc.syslog stop
/etc/rc.d/rc.syslog start


echo "Cleaning up /var/log/nginx/error.log then restarting the nginx daemon"
pkill -9 nginx
> /var/log/nginx/error.log &
> /var/log/nginx/error.log.1
/etc/rc.d/rc.nginx start