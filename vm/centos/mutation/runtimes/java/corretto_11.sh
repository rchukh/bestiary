#!/bin/bash -xe
##
# Installs Amazon Corretto 11 - https://aws.amazon.com/corretto/
#
# Mutation required:
# - base.sh
##
TMP_DIR=/tmp/$(uuidgen -t)

CORRETTO_VERSION=11.0.4.11-1
CORRETTO_DIST=java-11-amazon-corretto-devel-$CORRETTO_VERSION.x86_64.rpm

# Download and install Amazon Corretto
sudo mkdir -p $TMP_DIR
sudo curl -L -o $TMP_DIR/$CORRETTO_DIST https://d3pxv6yz143wms.cloudfront.net/11.0.4.11.1/$CORRETTO_DIST
sudo yum -y localinstall $TMP_DIR/$CORRETTO_DIST

# TODO: Check if this might be needed.
# sudo alternatives --config javac

# Show Version
java -version

# Clean up tmp files
sudo rm -f $TMP_DIR/$CORRETTO_DIST
