#!/bin/bash

# If the initial configuration was already done, just re-start the service
if [ -f /opt/bestiary/presto/.boostrap ]; then
    echo "Presto already configured."
    sudo service presto restart
    exit 0
fi
sudo mkdir -p /opt/bestiary/presto/

# Random UUID for node
NODE_ID=$(uuidgen)
# Cluster name (will show up in UI)
NODE_ENV="${ENV_NAME}"

sudo sed -i.bak \
         -e "s/node.id=.*/node.id=$NODE_ID/g" \
         -e "s/node.environment=.*/node.environment=$NODE_ENV/g" \
         /etc/presto/node.properties

# Download config
sudo gsutil cp gs://${GCS_CONFIG_BUCKET}/${GCS_CONFIG_OBJECT} /opt/bestiary/presto/config.zip
sudo unzip /opt/bestiary/presto/config.zip -d /opt/bestiary/presto/
sudo cat /opt/bestiary/presto/additional_hosts | sudo tee -a /etc/hosts

sudo mv /etc/presto/config.properties /etc/presto/config.properties.bak
sudo cp /opt/bestiary/presto/config.properties /etc/presto/config.properties
sudo mkdir -p /etc/presto/catalog
sudo chmod -R 0755 /etc/presto/catalog
sudo cp -R /opt/bestiary/presto/catalog/* /etc/presto/catalog
sudo chmod -R 0644 /etc/presto/catalog/*.properties
sudo chmod -R 0644 /etc/presto/*.properties
sudo chown -R presto:presto /etc/presto

sudo service presto restart

# Clean up
sudo rm -rf /opt/bestiary/presto/
# Mark the configuration as completed
sudo mkdir -p /opt/bestiary/presto/
sudo touch /opt/bestiary/presto/.boostrap
