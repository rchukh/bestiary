#!/bin/bash
##
# Installs Amazon Corretto 1.8 - https://aws.amazon.com/corretto/
#
# Mutation required:
# - base.sh
##
TMP_DIR=/tmp/$(uuidgen -t)

CORRETTO_VERSION=1.8.0_202.b08-2
CORRETTO_DIST=java-1.8.0-amazon-corretto-devel-$CORRETTO_VERSION.x86_64.rpm

# Download and install Amazon Corretto
sudo mkdir -p $TMP_DIR
sudo wget https://d2znqt9b1bc64u.cloudfront.net/$CORRETTO_DIST -O $TMP_DIR/$CORRETTO_DIST
sudo yum -y localinstall $TMP_DIR/$CORRETTO_DIST

# TODO: Check if this might be needed.
# sudo alternatives --config javac

# Show Version
java -version

# Clean up tmp files
sudo rm -f $TMP_DIR/$CORRETTO_DIST
