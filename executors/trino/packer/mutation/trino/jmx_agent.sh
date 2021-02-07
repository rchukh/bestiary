#!/bin/bash -xe
##
# Installs Prometheus JMX Agent - https://github.com/prometheus/jmx_exporter
#
# Mutation required:
# - base.sh
# - trino.sh
##
TRINO_CONF=/etc/trino
TRINO_JVM_CONF=$TRINO_CONF/jvm.config

PROMETHEUS_JAVAAGENT_VERSION=0.15.0
PROMETHEUS_JAVAAGENT=jmx_prometheus_javaagent-$PROMETHEUS_JAVAAGENT_VERSION.jar
PROMETHEUS_JAVAAGENT_DIR=/opt/prometheus/jmx_agent
PROMETHEUS_JAVAAGENT_PORT=8081
PROMETHEUS_JAVAAGENT_CONFIG=$TRINO_CONF/jmx_exporter.yaml

sudo mkdir -p $PROMETHEUS_JAVAAGENT_DIR
sudo wget https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/$PROMETHEUS_JAVAAGENT_VERSION/$PROMETHEUS_JAVAAGENT -O $PROMETHEUS_JAVAAGENT_DIR/$PROMETHEUS_JAVAAGENT
# Empty config
sudo touch $PROMETHEUS_JAVAAGENT_CONFIG

sudo tee -a $TRINO_JVM_CONF <<EOF
-javaagent:$PROMETHEUS_JAVAAGENT_DIR/$PROMETHEUS_JAVAAGENT=$PROMETHEUS_JAVAAGENT_PORT:$PROMETHEUS_JAVAAGENT_CONFIG
EOF
