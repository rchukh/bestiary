#!/bin/bash -xe

# Random UUID for node
NODE_ID=$(uuidgen)
# Cluster name (will show up in UI)
NODE_ENV="${PRESTOSQL_ENV_NAME}"
# Cluster Coordinator location (hostname/ip without http://)
DISCOVERY_URI="${PRESTOSQL_COORDINATOR}"

sudo sed -i.bak -e "s/node.id=.*/node.id=$NODE_ID/g" -e "s/node.environment=.*/node.environment=$NODE_ENV/g" /etc/presto/node.properties
sudo sed -i.bak -e "s/discovery.uri=.*/discovery.uri=http:\/\/$DISCOVERY_URI/g" /etc/presto/config.properties

sudo service presto restart