#!/bin/bash
##
# Installs Benchto Service - https://github.com/prestosql/benchto/tree/master/benchto-service
#
# Mutation required:
# - base.sh
##
TMP_DIR=/tmp/$(uuidgen -t)

SERVICE_VERSION=0.7
SERVICE_DIST=benchto-service-$SERVICE_VERSION.jar
SERVICE_DEST=/opt/benchto/service

# Download and install
sudo mkdir -p $TMP_DIR
sudo wget http://central.maven.org/maven2/io/prestosql/benchto/benchto-service/$SERVICE_VERSION/$SERVICE_DIST -O $TMP_DIR/$SERVICE_DIST
# TODO: "install"
# https://github.com/prestosql/benchto/blob/master/benchto-service/src/main/resources/application.yaml

# Clean up tmp files
sudo rm -f $TMP_DIR/$SERVICE_DIST
