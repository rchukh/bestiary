#!/bin/bash -xe

# Configure monit for PrestoSQL
sudo tee /etc/monit.d/presto > /dev/null <<EOF
set logfile syslog facility log_daemon
check process presto with pidfile /var/lib/presto/data/var/run/launcher.pid
   start program = "/etc/init.d/presto start"
   stop program  = "/etc/init.d/presto stop"
   if not exist then restart
EOF

sudo systemctl restart monit
