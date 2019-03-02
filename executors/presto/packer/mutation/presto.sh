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

# Prepare basic initialization script
# This is need to generate specific node id for different VM's
sudo mkdir -p /opt/bestiary/presto
sudo tee -a /opt/bestiary/presto/init.sh << 'EOF'
#!/bin/bash

# Random UUID for node
NODE_ID=$(uuidgen)
# Cluster name (will show up in UI)
NODE_ENV=${PRESTOSQL_ENV_NAME:=bestiary}
# Cluster Coordinator location (hostname/ip without http://)
DISCOVERY_URI=${PRESTOSQL_COORDINATOR:=localhost:8080}

sudo sed -i.bak -e "s/node.id=.*/node.id=$NODE_ID/g" -e "s/node.environment=.*/node.environment=$NODE_ENV/g" /etc/presto/node.properties
sudo sed -i.bak -e "s/discovery.uri=.*/discovery.uri=http:\/\/$DISCOVERY_URI/g" /etc/presto/config.properties

sudo service presto restart
EOF
sudo chmod +x /opt/bestiary/presto/init.sh

# Clean up tmp files
sudo rm -f $TMP_DIR/$PRESTOSQL_DIST
