#!/bin/bash
##
# Installs Benchto - https://github.com/trinodb/benchto/tree/master/benchto-driver
#
# Mutation required:
# - base.sh
##
TMP_DIR=/tmp/bestiary/$(uuidgen -t)

DRIVER_VERSION=0.14
DRIVER_DIST=benchto-driver-$DRIVER_VERSION.jar
DRIVER_DESTINATION=/opt/benchto/driver

# Download and install
sudo mkdir -p $TMP_DIR
sudo curl -L -o $TMP_DIR/$DRIVER_DIST https://repo1.maven.org/maven2/io/trino/benchto/benchto-driver/$DRIVER_VERSION/$DRIVER_DIST

sudo mkdir -p $DRIVER_DESTINATION
sudo mv $TMP_DIR/$DRIVER_DIST $DRIVER_DESTINATION

# Prepare sample configuration
sudo tee $DRIVER_DESTINATION/application-bestiary.yaml.template <<EOF
# environment on which benchmarks are run
# it should map to environment mapped in benchmark-service
environment:
  name: BESTIARY

benchmark-service:
  url: http://localhost:18080

# data-sources section which lists all jdbc drivers which can be used in benchmarks
data-sources:
  trino:
    url: jdbc:trino://_TRINO_URL_:_TRINO_PORT_
    username: _TRINO_USERNAME_
    password: _TRINO_PASSWORD_
    driver-class-name: io.trino.jdbc.TrinoDriver

# macroExecutions:
#   # macro executed before all benchmarks
#   beforeAll: MACRO-NAME
#   # macro executed after all benchmarks
#   afterAll: MACRO-NAME

# # defines list of macros which are executed using 'bash'
# macros:
#   sample-macros:
#     command: echo "sample-macros"

# TODO: Create annotation directly in Grafana (since only Native annotations support ranges)
#       http://docs.grafana.org/http_api/annotations/#create-annotation
# TODO: Separate 'metrics.collection.enabled' from Graphite (change ExecutionSynchronizer) 
benchmark:
  feature:
    graphite:
      event.reporting.enabled: true
      metrics.collection.enabled: true

EOF


# TODO: Prepare Samples https://github.com/trinodb/trino/tree/master/testing/trino-benchto-benchmarks/src/main/resources
sudo mkdir -p $DRIVER_DESTINATION/data/sql
sudo mkdir -p $DRIVER_DESTINATION/data/benchmarks/trino
sudo mkdir -p $DRIVER_DESTINATION/data/overrides

sudo tee $DRIVER_DESTINATION/samplerun.sh <<EOF
#!/bin/bash

java -Xmx1g -jar $DRIVER_DIST \
    --sql data/sql \
    --benchmarks data/benchmarks \
    --activeBenchmarks=trino/tpcds,trino/tpch \
    --profile=bestiary

EOF


# Clean up tmp files
sudo rm -rf $TMP_DIR/
