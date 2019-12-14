#!/bin/bash -xe
##
# Installs Grafana - https://grafana.com/
##
TMP_DIR=/tmp/bestiary/$(uuidgen -t)

VERSION=6.5.2-1
DIST=grafana-$VERSION.x86_64.rpm

# Download and install
sudo mkdir -p $TMP_DIR
sudo yum -y install initscripts fontconfig freetype* urw-fonts
sudo curl -L -o $TMP_DIR/$DIST https://dl.grafana.com/oss/release/$DIST
sudo yum -y localinstall $TMP_DIR/$DIST

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

# Clean up tmp files
sudo rm -rf $TMP_DIR/
