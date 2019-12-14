#!/bin/bash -xe
##
# Installs Prometheus remote storage adapter for PostgreSQL - https://github.com/timescale/prometheus-postgresql-adapter
#
# NOTE:
# - Uses default configuration for local PostgreSQL and local Prometheus Server.
#   Any changes should be propagated during provisioning by replacing the Systemd service:
#   /etc/systemd/system/prometheus-postgresql-adapter.service
# - Prometheus Server should be explicitly configured to use this adapter separately
##
TMP_DIR=/tmp/bestiary/$(uuidgen -t)

PROM_PG_VERSION=0.6.0
PROM_PG_DIST=prometheus-postgresql-adapter-$PROM_PG_VERSION-linux-amd64.tar.gz

PROM_PG_USER=prometheus_pg
PROM_PG_DESTINATION=/opt/prometheus/postgresql-adapter

# Download and install
sudo mkdir -p $TMP_DIR
sudo curl -L -o $TMP_DIR/$PROM_PG_DIST https://github.com/timescale/prometheus-postgresql-adapter/releases/download/v$PROM_PG_VERSION/$PROM_PG_DIST
sudo mkdir -p $PROM_PG_DESTINATION
sudo tar -xzf $TMP_DIR/$PROM_PG_DIST -C $PROM_PG_DESTINATION

# Create a system account without shell
sudo useradd -r --shell /bin/false $PROM_PG_USER
sudo chown -R $PROM_PG_USER:$PROM_PG_USER $PROM_PG_DESTINATION

# Add a service
sudo tee /etc/systemd/system/prometheus-postgresql-adapter.service <<EOF
[Unit]
Description=Prometheus remote storage adapter for PostgreSQL
AssertPathExists=$PROM_PG_DESTINATION
After=syslog.target
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=3
WorkingDirectory=$PROM_PG_DESTINATION
User=$PROM_PG_USER
Group=$PROM_PG_USER
ExecStartPre=/bin/sleep 10
ExecStart=$PROM_PG_DESTINATION/prometheus-postgresql-adapter \
  -pg.host "localhost" -pg.port "5432" \
  -pg.user "postgres" -pg.password "$POSTGRESQL_PASSWORD" \
  -pg.database "prometheus" -pg.schema "prometheus" -pg.table "metrics" \
  -web.listen-address ":9201" -log.level "info"
ExecReload=/bin/kill -SIGHUP \$MAINPID
ExecStop=/bin/kill -SIGINT \$MAINPID

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable prometheus-postgresql-adapter
sudo systemctl start prometheus-postgresql-adapter

# Clean up tmp files
sudo rm -rf $TMP_DIR/
