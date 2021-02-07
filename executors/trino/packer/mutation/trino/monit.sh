#!/bin/bash -xe

# Configure monit for Trino
sudo tee /etc/monit.d/trino > /dev/null <<EOF
set logfile syslog facility log_daemon
check process trino with pidfile /var/lib/trino/data/var/run/launcher.pid
   start program = "/etc/init.d/trino start"
   stop program  = "/etc/init.d/trino stop"
   if not exist then restart
EOF

sudo systemctl restart monit
