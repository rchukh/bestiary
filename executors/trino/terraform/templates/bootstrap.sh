#!/bin/bash

# If the initial configuration was already done, just re-start the service
if [ -f /opt/bestiary/trino/.boostrap ]; then
    echo "Trino already configured."
    sudo service trino restart
    exit 0
fi
sudo mkdir -p /opt/bestiary/trino/

# Random UUID for node
NODE_ID=$(uuidgen)
# Cluster name (will show up in UI)
NODE_ENV="${ENV_NAME}"

sudo sed -i.bak \
         -e "s/node.id=.*/node.id=$NODE_ID/g" \
         -e "s/node.environment=.*/node.environment=$NODE_ENV/g" \
         /etc/trino/node.properties

# Download config
sudo gsutil cp gs://${GCS_CONFIG_BUCKET}/${GCS_CONFIG_OBJECT} /opt/bestiary/trino/config.zip
sudo unzip /opt/bestiary/trino/config.zip -d /opt/bestiary/trino/
sudo cat /opt/bestiary/trino/additional_hosts | sudo tee -a /etc/hosts

sudo mv /etc/trino/config.properties /etc/trino/config.properties.bak
sudo cp /opt/bestiary/trino/config.properties /etc/trino/config.properties
sudo mkdir -p /etc/trino/catalog
sudo chmod -R 0755 /etc/trino/catalog
sudo cp -R /opt/bestiary/trino/catalog/* /etc/trino/catalog
sudo chmod -R 0644 /etc/trino/catalog/*.properties
sudo chmod -R 0644 /etc/trino/*.properties
sudo chown -R trino:trino /etc/trino

sudo service trino restart

# Clean up
sudo rm -rf /opt/bestiary/trino/
# Mark the configuration as completed
sudo mkdir -p /opt/bestiary/trino/
sudo touch /opt/bestiary/trino/.boostrap
