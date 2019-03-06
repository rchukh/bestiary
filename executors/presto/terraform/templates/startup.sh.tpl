#!/bin/bash -xe

# Random UUID for node
NODE_ID=$(uuidgen)
# Cluster name (will show up in UI)
NODE_ENV="${PRESTOSQL_ENV_NAME}"

sudo sed -i.bak \
         -e "s/node.id=.*/node.id=$NODE_ID/g" \
         -e "s/node.environment=.*/node.environment=$NODE_ENV/g"
         /etc/presto/node.properties

sudo mv /etc/presto/config.properties /etc/presto/config.properties.bak
sudo tee /etc/presto/config.properties <<EOF
$PRESTOSQL_CONFIG
EOF

sudo service presto restart