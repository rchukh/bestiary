#!/bin/bash -xe
##
# Configures Fluent Bit for Presto QueryLog.
# TODO: Test (especially rotation)
##
DB_PATH=/var/log/fluentbit_presto_querylog
QUERYLOG_LOGFILE=/var/log/presto/presto-querylog/presto-querylog.log
sudo mkdir -p $DB_PATH
sudo tee /etc/td-agent-bit/fluentbit_presto_querylog.conf << 'EOF'
[INPUT]
    Name        tail
    Tag         presto_querylog
    Path        ${QUERYLOG_LOGFILE}
    DB          ${DB_PATH}/logs.db

[OUTPUT]
    Name          forward
    Match         presto_querylog
    Host          ${FLUENTD_HOST}
    Port          ${FLUENTD_PORT}
    Shared_Key    ${FLUENTD_SECRET}
    Self_Hostname flb.local
    tls           off
    tls.verify    off
EOF

sudo systemctl restart td-agent-bit
sudo systemctl status td-agent-bit
