#!/bin/sh -xe

TMP_DIR=/tmp/bestiary/$(uuidgen -t)
sudo mkdir -p $TMP_DIR

# Create hive user
sudo useradd -m -d /home/hive -s /bin/bash hive

# Prepare Hive components
HIVE_VERSION=2.3.5
HIVE_DIST=apache-hive-$HIVE_VERSION-bin.tar.gz
HIVE_DIR=/opt/hive/metastore
sudo curl -L -o $TMP_DIR/$HIVE_DIST "https://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename=hive/hive-$HIVE_VERSION/$HIVE_DIST"
sudo mkdir -p $HIVE_DIR
sudo tar -xzf $TMP_DIR/$HIVE_DIST -C $HIVE_DIR --strip-components=1
sudo mkdir -p $HIVE_DIR/logs
sudo chown -R hive:hive $HIVE_DIR

# Provide Hadoop components
HADOOP_VERSION=2.9.2
HADOOP_DIST=hadoop-$HADOOP_VERSION.tar.gz
HADOOP_DIR=/opt/hadoop
sudo curl -L -o $TMP_DIR/$HADOOP_DIST "https://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename=hadoop/core/hadoop-$HADOOP_VERSION/$HADOOP_DIST"
sudo mkdir -p $HADOOP_DIR
sudo tar -xzf $TMP_DIR/$HADOOP_DIST -C $HADOOP_DIR --strip-components=1
sudo chown -R hive:hive $HADOOP_DIR

# Add MySQL driver to Hive libraries
MYSQL_JDBC_VERSION=8.0.17
MYSQL_JDBC_DIST=mysql-connector-java-$MYSQL_JDBC_VERSION.jar
sudo curl -L -o $HIVE_DIR/lib/$MYSQL_JDBC_DIST https://repo1.maven.org/maven2/mysql/mysql-connector-java/$MYSQL_JDBC_VERSION/$MYSQL_JDBC_DIST

# Add Prometheus JMX Exporter
PROMETHEUS_AGENT_VERSION=0.12.0
PROMETHEUS_AGENT=jmx_prometheus_javaagent-$PROMETHEUS_AGENT_VERSION.jar
PROMETHEUS_AGENT_PORT=8081
PROMETHEUS_AGENT_CONFIG=$HIVE_DIR/jmx_exporter.yaml
sudo curl -L -o $HIVE_DIR/$PROMETHEUS_AGENT https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/$PROMETHEUS_AGENT_VERSION/$PROMETHEUS_AGENT
sudo touch $PROMETHEUS_AGENT_CONFIG

# Add GCS Connector
GCS_CONNECTOR_VERSION=1.9.17
GCS_CONNECTOR=gcs-connector-hadoop2-$GCS_CONNECTOR_VERSION-shaded.jar
HIVE_CONNECTORS_DIR=/opt/hive/metastore/connectors
sudo mkdir -p $HIVE_CONNECTORS_DIR
sudo curl -L -o $HIVE_CONNECTORS_DIR/$GCS_CONNECTOR https://repo1.maven.org/maven2/com/google/cloud/bigdataoss/gcs-connector/hadoop2-$GCS_CONNECTOR_VERSION/$GCS_CONNECTOR
sudo chown -R hive:hive $HIVE_CONNECTORS_DIR

# Configure Hive (Metastore)
sudo cp $HIVE_DIR/conf/hive-env.sh.template $HIVE_DIR/conf/hive-env.sh

sudo tee -a $HIVE_DIR/conf/hive-env.sh <<EOF
# Custom configurations

export JAVA_HOME="/usr/lib/jvm/jre"
export HADOOP_HOME=$HADOOP_DIR
export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop
export HADOOP_COMMON_HOME=\$HADOOP_HOME

export HIVE_HOME=$HIVE_DIR

export PATH=\$HIVE_HOME/bin:\$HADOOP_HOME/bin:\$PATH

# In order for Xms/Xmx in HIVE_METASTORE_HADOOP_OPTS to even work in the first place:
# - the HADOOP_HEAPSIZE _must_ be set to even or higher value.
# - the HADOOP_CLIENT_OPTS _must_ be set to even or higher value.
# - the HADOOP_OPTS _must_ not be set, or be set as empty.
export HADOOP_HEAPSIZE=4096
export HADOOP_CLIENT_OPTS="-Xms4G -Xmx4G -XX:+AlwaysPreTouch"
export CUSTOM_HIVE_METASTORE_GC_OPTS=" -Xms4G -Xmx4G -XX:+UseG1GC -XX:G1HeapRegionSize=32M -XX:-UseGCOverheadLimit -XX:+ExplicitGCInvokesConcurrent"

export HIVE_METASTORE_HADOOP_OPTS=" -javaagent:$HIVE_DIR/$PROMETHEUS_AGENT=$PROMETHEUS_AGENT_PORT:$PROMETHEUS_AGENT_CONFIG"
export HIVE_METASTORE_HADOOP_OPTS=" \$HIVE_METASTORE_HADOOP_OPTS \$CUSTOM_HIVE_METASTORE_GC_OPTS"
export HIVE_METASTORE_HADOOP_OPTS=" \$HIVE_METASTORE_HADOOP_OPTS -Dhive.log.dir=$HIVE_DIR/logs -Dhive.log.file=hive-metastore.log -Dhive.log.threshold=INFO"
export HADOOP_CLASSPATH=" \$HADOOP_CLASSPATH:$HIVE_CONNECTORS_DIR/*"

EOF

# Prepare Hive Metastore Service
sudo tee /etc/systemd/system/hive-metastore.service << END
[Unit]
Description=Hive Metastore
Documentation=https://cwiki.apache.org/confluence/display/Hive/AdminManual+Metastore+Administration#AdminManualMetastoreAdministration-RemoteMetastoreServer
Requires=network-online.target
After=network-online.target

[Service]
User=hive
Restart=always
RestartSec=3
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=hive-metastore
WorkingDirectory=/opt/hive/metastore
ExecStart=/opt/hive/metastore/bin/hive --service metastore

[Install]
WantedBy=multi-user.target
END

# See bootstrap.sh in ../../terraform/templates folder
#sudo systemctl daemon-reload
#sudo systemctl enable hive-metastore
#sudo systemctl start hive-metastore

# Clean up tmp files
sudo rm -rf $TMP_DIR/
