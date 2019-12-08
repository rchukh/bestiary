#!/bin/bash -xe
##
# Installs Presto QueryLog - https://github.com/rchukh/presto-querylog
#
# Mutation required:
# - base.sh
# - presto.sh
##
TMP_DIR=/tmp/bestiary/$(uuidgen -t)
sudo mkdir -p $TMP_DIR

PRESTO_CONF_DIR=/etc/presto
PRESTO_PLUGIN_DIR=/usr/lib/presto/plugin
PRESTO_LISTENER_CONF=$PRESTO_CONF_DIR/event-listener.properties

QUERYLOG_VERSION="0.3"
QUERYLOG_DIST="presto-querylog-$QUERYLOG_VERSION-dist.zip"
QUERYLOG_CONF=$PRESTO_CONF_DIR/presto-querylog-log4j2.xml
QUERYLOG_PLUGIN_DIR=$PRESTO_PLUGIN_DIR/presto-querylog
QUERYLOG_LOG_DIR=/var/log/presto/presto-querylog

# Download and unpack
sudo curl -L -o $TMP_DIR/$QUERYLOG_DIST "https://jitpack.io/com/github/rchukh/presto-querylog/$QUERYLOG_VERSION/$QUERYLOG_DIST"
sudo mkdir -p $QUERYLOG_PLUGIN_DIR
sudo unzip $TMP_DIR/$QUERYLOG_DIST -d $QUERYLOG_PLUGIN_DIR
sudo chown -R presto:presto $QUERYLOG_PLUGIN_DIR
sudo chmod 0755 $QUERYLOG_PLUGIN_DIR

# Prepare default config
sudo mkdir -p $QUERYLOG_LOG_DIR
sudo chown presto:presto $QUERYLOG_LOG_DIR
sudo chmod 0755 $QUERYLOG_LOG_DIR
sudo touch $QUERYLOG_CONF
sudo chown presto:presto $QUERYLOG_CONF
sudo chmod 0644 $QUERYLOG_CONF
sudo tee -a $QUERYLOG_CONF <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Configuration status="warn" name="PrestoQueryLog" packages="">
    <Appenders>
        <RollingFile name="JsonRollingFile">
            <FileName>$QUERYLOG_LOG_DIR/presto-querylog.log</FileName>
            <FilePattern>$QUERYLOG_LOG_DIR/%d{yyyy-MM-dd-hh}-%i.log</FilePattern>
            <JsonLayout charset="UTF-8" includeStacktrace="false"
                        compact="true" eventEol="true" objectMessageAsJsonObject="true"/>
            <Policies>
                <SizeBasedTriggeringPolicy size="100 MB"/>
            </Policies>
            <DefaultRolloverStrategy max="10"/>
        </RollingFile>
    </Appenders>

    <Loggers>
        <Root level="INFO">
            <AppenderRef ref="JsonRollingFile"/>
        </Root>
    </Loggers>
</Configuration>
EOF

# Enable plugin
sudo touch $PRESTO_LISTENER_CONF
sudo chown presto:presto $PRESTO_LISTENER_CONF
sudo chmod 0644 $PRESTO_LISTENER_CONF
sudo tee -a $PRESTO_LISTENER_CONF <<EOF
event-listener.name=presto-querylog
presto.querylog.log4j2.configLocation=$QUERYLOG_CONF
presto.querylog.log.queryCompletedEvent=true
presto.querylog.log.queryCreatedEvent=false
presto.querylog.log.splitCompletedEvent=false
EOF
