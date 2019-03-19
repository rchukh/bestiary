#!/bin/bash
##
# Installs Benchto - https://github.com/prestosql/benchto/tree/master/benchto-driver
#
# Mutation required:
# - base.sh
##
TMP_DIR=/tmp/$(uuidgen -t)

DRIVER_VERSION=0.7
DRIVER_DIST=benchto-driver-$DRIVER_VERSION.jar
DRIVER_DESTINATION=/opt/benchto/driver

# Download and install
sudo mkdir -p $TMP_DIR
sudo wget http://central.maven.org/maven2/io/prestosql/benchto/benchto-driver/$DRIVER_VERSION/$DRIVER_DIST -O $TMP_DIR/$DRIVER_DIST

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
  presto:
    url: jdbc:presto://_PRESTO_URL_:_PRESTO_PORT_
    username: _PRESTO_USERNAME_
    password: _PRESTO_PASSWORD_
    driver-class-name: com.facebook.presto.jdbc.PrestoDriver
    # driver-class-name: io.prestosql.jdbc.PrestoDriver

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


# TODO: Prepare Samples https://github.com/prestosql/presto/tree/master/presto-benchto-benchmarks/src/main/resources
sudo mkdir -p $DRIVER_DESTINATION/data/sql
sudo mkdir -p $DRIVER_DESTINATION/data/benchmarks/presto
sudo mkdir -p $DRIVER_DESTINATION/data/overrides

sudo tee $DRIVER_DESTINATION/samplerun.sh <<EOF
#!/bin/bash

java -Xmx1g -jar $DRIVER_DIST \
    --sql data/sql \
    --benchmarks data/benchmarks \
    --activeBenchmarks=presto/tpcds,presto/tpch \
    --profile=bestiary

EOF


# Clean up tmp files
sudo rm -f $TMP_DIR/$DRIVER_DIST
