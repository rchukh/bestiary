#!/bin/bash
##
# Installs Benchto Service - https://github.com/trinodb/benchto/tree/master/benchto-service
#
# Mutation required:
# - base.sh
##
TMP_DIR=/tmp/bestiary/$(uuidgen -t)

SERVICE_VERSION=0.14
SERVICE_DIST=benchto-service-$SERVICE_VERSION.jar
SERVICE_DESTINATION=/opt/benchto/service

# Download and install
sudo mkdir -p $TMP_DIR
sudo curl -L -o $TMP_DIR/$SERVICE_DIST https://repo1.maven.org/maven2/io/trino/benchto/benchto-service/$SERVICE_VERSION/$SERVICE_DIST

sudo mkdir -p $SERVICE_DESTINATION
sudo mv $TMP_DIR/$SERVICE_DIST $SERVICE_DESTINATION

# Prepare initial configuration
sudo tee $SERVICE_DESTINATION/application.yaml <<EOF
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/$BENCHTO_DB
    username: $BENCHTO_DB_USER
    password: $BENCHTO_DB_PASSWORD
    driver-class-name: org.postgresql.Driver
  jpa:
    open-in-view: false
    hibernate.ddl-auto: validate
    properties:
      hibernate.cache.region.factory_class: org.hibernate.cache.ehcache.EhCacheRegionFactory
      hibernate.cache.use_second_level_cache: true
      hibernate.cache.use_query_cache: true
      javax.persistence.sharedCache.mode: ENABLE_SELECTIVE

EOF

# Create Database on Local PostgreSQL installation
if [ "$BENCHTO_CREATE_DATABASE" = true ] ; then
  sudo -u postgres psql -c "CREATE DATABASE $BENCHTO_DB;"
fi

sudo tee $SERVICE_DESTINATION/samplerun.sh <<EOF
#!/bin/bash

java -Xmx1g -jar $SERVICE_DIST
EOF

# Clean up tmp files
sudo rm -rf $TMP_DIR
