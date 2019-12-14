#!/bin/bash -xe
##
# Installs Fluent Bit - https://fluentbit.io/
##

sudo tee -a /etc/yum.repos.d/td-agent-bit.repo <<EOF
[td-agent-bit]
name = TD Agent Bit
baseurl = http://packages.fluentbit.io/centos/7
gpgcheck=1
gpgkey=http://packages.fluentbit.io/fluentbit.key
enabled=1
EOF

# Install Fluent Bit
sudo yum -y install td-agent-bit

# Replace Defaults
sudo tee /etc/td-agent-bit/td-agent-bit.conf <<EOL
[SERVICE]
    # Flush
    # =====
    # Set an interval of seconds before to flush records to a destination
    Flush        5
    # Daemon
    # ======
    # Instruct Fluent Bit to run in foreground or background mode.
    Daemon       Off
    # Log_Level
    # =========
    # Set the verbosity level of the service, values can be:
    #
    # - error
    # - warning
    # - info
    # - debug
    # - trace
    #
    # By default 'info' is set, that means it includes 'error' and 'warning'.
    Log_Level    info
    # Parsers_File
    # ============
    # Specify an optional 'Parsers' configuration file
    Parsers_File parsers.conf
    Plugins_File plugins.conf
    # HTTP Server
    # ===========
    # Enable/Disable the built-in HTTP Server for metrics
    HTTP_Server  Off
    HTTP_Listen  0.0.0.0
    HTTP_Port    2020

# Include external configurations
@INCLUDE fluentbit_*.conf

EOL
sudo tee /etc/td-agent-bit/fluentbit_default.conf <<EOL
[INPUT]
    Name cpu
    Tag  cpu.local
    # Interval Sec
    # ====
    # Read interval (sec) Default: 1
    Interval_Sec 10

[OUTPUT]
    Name  stdout
    Match *
EOL

# Start Fluent Bit
sudo systemctl enable td-agent-bit
sudo systemctl start td-agent-bit
sudo systemctl status td-agent-bit
