#!/bin/bash
##
# Installs PrestoSQL - https://prestosql.io/
#
# Mutation required:
# - base.sh
##
TMP_DIR=/tmp/$(uuidgen -t)

PRESTOSQL_VERSION=303
PRESTOSQL_DIST=presto-server-rpm-$PRESTOSQL_VERSION.rpm

# Download and install Amazon Corretto
sudo mkdir -p $TMP_DIR
sudo wget http://central.maven.org/maven2/io/prestosql/presto-server-rpm/$PRESTOSQL_VERSION/$PRESTOSQL_DIST -O $TMP_DIR/$PRESTOSQL_DIST
sudo yum -y localinstall $TMP_DIR/$PRESTOSQL_DIST

# Clean up tmp files
sudo rm -f $TMP_DIR/$PRESTOSQL_DIST
