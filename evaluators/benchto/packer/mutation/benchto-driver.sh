#!/bin/bash
##
# Installs Benchto - https://github.com/prestosql/benchto/tree/master/benchto-driver
#
# Mutation required:
# - base.sh
##
TMP_DIR=/tmp/$(uuidgen -t)

DRIVER_VERSION=0.7
DRIVER_DIST=benchto-driver-$DRIVER_VERSION.jar
DRIVER_DEST=/opt/benchto/driver

# Download and install
sudo mkdir -p $TMP_DIR
sudo wget http://central.maven.org/maven2/io/prestosql/benchto/benchto-driver/$DRIVER_VERSION/$DRIVER_DIST -O $TMP_DIR/$DRIVER_DIST
# TODO: "install"
# https://github.com/prestosql/benchto/tree/master/benchto-driver

# Clean up tmp files
sudo rm -f $TMP_DIR/$DRIVER_DIST
