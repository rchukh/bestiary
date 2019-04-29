#!/bin/bash -xe
##
# Installs Prometheus Node Exporter - https://github.com/prometheus/node_exporter/
#
# Mutation required:
# - base.sh
##
TMP_DIR=/tmp/$(uuidgen -t)

NODE_EXPORTER_VERSION=0.17.0
NODE_EXPORTER_DIST=node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz

# Download and unpack node_exporter
sudo mkdir -p $TMP_DIR
sudo wget https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/$NODE_EXPORTER_DIST -O $TMP_DIR/$NODE_EXPORTER_DIST
sudo mkdir -p /opt/observer/node_exporter
sudo tar -xzf $TMP_DIR/$NODE_EXPORTER_DIST -C /opt/observer/node_exporter --strip-components=1

# Add a service for node_exporter
sudo tee -a /etc/systemd/system/node_exporter.service <<END
[Unit]
Description=Prometheus Node Exporter
After=network-online.target

[Service]
User=nobody
Restart=always
RestartSec=3
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=node_exporter
ExecStart=/opt/observer/node_exporter/node_exporter

[Install]
WantedBy=multi-user.target
END

# Enable and start the node_exporter service
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# Clean up tmp files
sudo rm -f $TMP_DIR/$NODE_EXPORTER_DIST
