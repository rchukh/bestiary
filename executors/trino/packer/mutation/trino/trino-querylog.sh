#!/bin/bash -xe
##
# Installs Trino QueryLog - https://github.com/rchukh/trino-querylog
#
# Mutation required:
# - base.sh
# - trino.sh
##
TMP_DIR=/tmp/bestiary/$(uuidgen -t)
sudo mkdir -p $TMP_DIR

TRINO_CONF_DIR=/etc/trino
TRINO_PLUGIN_DIR=/usr/lib/trino/plugin
TRINO_LISTENER_CONF=$TRINO_CONF_DIR/event-listener.properties

QUERYLOG_VERSION="0.4"
QUERYLOG_DIST="trino-querylog-$QUERYLOG_VERSION-dist.zip"
QUERYLOG_CONF=$TRINO_CONF_DIR/trino-querylog-log4j2.xml
QUERYLOG_PLUGIN_DIR=$TRINO_PLUGIN_DIR/trino-querylog
QUERYLOG_LOG_DIR=/var/log/trino/trino-querylog

# Download and unpack
sudo curl -L -o $TMP_DIR/$QUERYLOG_DIST "https://jitpack.io/com/github/rchukh/trino-querylog/$QUERYLOG_VERSION/$QUERYLOG_DIST"
sudo mkdir -p $QUERYLOG_PLUGIN_DIR
sudo unzip $TMP_DIR/$QUERYLOG_DIST -d $QUERYLOG_PLUGIN_DIR
sudo chown -R trino:trino $QUERYLOG_PLUGIN_DIR
sudo chmod 0755 $QUERYLOG_PLUGIN_DIR

# Prepare default config
sudo mkdir -p $QUERYLOG_LOG_DIR
sudo chown trino:trino $QUERYLOG_LOG_DIR
sudo chmod 0755 $QUERYLOG_LOG_DIR
sudo touch $QUERYLOG_CONF
sudo chown trino:trino $QUERYLOG_CONF
sudo chmod 0644 $QUERYLOG_CONF
sudo tee -a $QUERYLOG_CONF <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Configuration status="warn" name="TrinoQueryLog" packages="">
    <Appenders>
        <RollingFile name="JsonRollingFile">
            <FileName>$QUERYLOG_LOG_DIR/trino-querylog.log</FileName>
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
sudo touch $TRINO_LISTENER_CONF
sudo chown trino:trino $TRINO_LISTENER_CONF
sudo chmod 0644 $TRINO_LISTENER_CONF
sudo tee -a $TRINO_LISTENER_CONF <<EOF
event-listener.name=trino-querylog
trino.querylog.log4j2.configLocation=$QUERYLOG_CONF
trino.querylog.log.queryCompletedEvent=true
trino.querylog.log.queryCreatedEvent=false
trino.querylog.log.splitCompletedEvent=false
EOF
