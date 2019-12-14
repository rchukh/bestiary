#!/bin/bash -x

# If the initial configuration was already done, just re-start the service
if [ -f /opt/bestiary/hive-metastore/.boostrap ]; then
    echo "Hive Metastore already configured."
    sudo service hive-metastore restart
    exit 0
fi
sudo mkdir -p /opt/bestiary/hive-metastore/

##
# Configure CloudSQL Proxy
##
if [ "${ENABLE_CLOUD_SQL_PROXY}" -eq 1 ]; then
  sudo tee -a /etc/systemd/system/cloud_sql_proxy.service.d/settings.conf << 'EOF'
[Service]
Environment=INSTANCE_CONNECTION_NAME=${INSTANCE_CONNECTION_NAME}
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable cloud_sql_proxy
  sudo systemctl start cloud_sql_proxy
  # Wait for CloudSQL Proxy to establish connection
  sleep 10
fi

##
# Configure Hive Metastore
##
sudo gsutil cp gs://${GCS_CONFIG_BUCKET}/${GCS_CONFIG_OBJECT} /opt/bestiary/hive-metastore/hive-metastore.zip
sudo unzip /opt/bestiary/hive-metastore/hive-metastore.zip -d /opt/bestiary/hive-metastore/
sudo cat /opt/bestiary/hive-metastore/additional_hosts | sudo tee -a /etc/hosts
sudo cp /opt/bestiary/hive-metastore/hivemetastore-site.xml /opt/hive/metastore/conf/hivemetastore-site.xml
sudo cp /opt/bestiary/hive-metastore/hive-log4j2.properties /opt/hive/metastore/conf/hive-log4j2.properties
sudo chmod -R 0644 /opt/hive/metastore/conf/*
sudo chmod -R 0755 /opt/hive/metastore/conf /opt/hive/metastore/conf/hive-env.sh
sudo chown -R hive:hive /opt/hive/metastore/conf/

# TODO: Extend with image size variable
sudo sed -i "s/export HADOOP_HEAPSIZE=.*/export HADOOP_HEAPSIZE=4096/g" /opt/hive/metastore/conf/hive-env.sh
sudo sed -i "s/export HADOOP_CLIENT_OPTS=.*/export HADOOP_CLIENT_OPTS=\"-Xms4G -Xmx4G -XX:+AlwaysPreTouch\"/g" /opt/hive/metastore/conf/hive-env.sh
sudo sed -i "s/export CUSTOM_HIVE_METASTORE_GC_OPTS=.*/export CUSTOM_HIVE_METASTORE_GC_OPTS=\" -Xmx4G -XX:+UseG1GC -XX:G1HeapRegionSize=32M -XX:-UseGCOverheadLimit -XX:+ExplicitGCInvokesConcurrent\"/g" /opt/hive/metastore/conf/hive-env.sh

##
# Initialize database
##
sudo su hive -c "/opt/hive/metastore/bin/schematool -dbType mysql -info"
SCHEMA_STATUS=$?
if [ $SCHEMA_STATUS -ne 0 ]; then
    sudo su hive -c "/opt/hive/metastore/bin/schematool -dbType mysql -initSchema"
fi
##
# Migrate to newer version of database schema.
##
# sudo su hive -c "/opt/hive/metastore/bin/schematool -dbType mysql -upgradeSchema"

# Finally - (re-)boot the metastore
sudo systemctl enable hive-metastore
sudo systemctl start hive-metastore

# Clean up
sudo rm -rf /opt/bestiary/hive-metastore/
# Mark the configuration as completed
sudo mkdir -p /opt/bestiary/hive-metastore/
sudo touch /opt/bestiary/hive-metastore/.boostrap
