#!/bin/bash
##
# Installs Trino - https://trino.io/
#
# Mutation required:
# - base.sh
##
TMP_DIR=/tmp/$(uuidgen -t)

TRINO_VERSION=326
TRINO_DIST=trino-server-rpm-$TRINO_VERSION.rpm

# Download and install
sudo mkdir -p $TMP_DIR
sudo wget https://repo1.maven.org/maven2/io/trino/trino-server-rpm/$TRINO_VERSION/$TRINO_DIST -O $TMP_DIR/$TRINO_DIST
sudo yum -y localinstall $TMP_DIR/$TRINO_DIST

# Clean up tmp files
sudo rm -f $TMP_DIR/$TRINO_DIST
