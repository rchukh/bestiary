#!/bin/bash
##
# Installs Prometheus - https://prometheus.io/
#
# NOTE:
# - Uses default configuration.
#   Any changes should be propagated during provisioning to $PROM_DESTINATION/prometheus.yml.
##
TMP_DIR=/tmp/bestiary/$(uuidgen -t)

PROM_VERSION=2.9.2
PROM_DIST=prometheus-$PROM_VERSION.linux-amd64.tar.gz
PROM_USER=prometheus
PROM_DESTINATION=/opt/prometheus/server

# Download and install
sudo mkdir -p $TMP_DIR
sudo curl -L -o $TMP_DIR/$PROM_DIST https://github.com/prometheus/prometheus/releases/download/v$PROM_VERSION/$PROM_DIST
sudo mkdir -p $PROM_DESTINATION
sudo tar -xzf $TMP_DIR/$PROM_DIST -C $PROM_DESTINATION --strip-components=1

# Create a system account without shell
sudo useradd -r --shell /bin/false $PROM_USER
sudo chown -R $PROM_USER:$PROM_USER $PROM_DESTINATION

# Add a service
sudo tee /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus Server
AssertPathExists=$PROM_DESTINATION

[Service]
Type=simple
WorkingDirectory=$PROM_DESTINATION
User=$PROM_USER
Group=$PROM_USER
ExecStart=$PROM_DESTINATION/prometheus --config.file=$PROM_DESTINATION/prometheus.yml --log.level=info
ExecReload=/bin/kill -SIGHUP \$MAINPID
ExecStop=/bin/kill -SIGINT \$MAINPID

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

# Clean up tmp files
sudo rm -rf $TMP_DIR/
