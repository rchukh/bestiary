#!/bin/bash
##
# Installs:
# - PostgreSQL 11
# - TimescaleDB extension - https://github.com/timescale/timescaledb
# - Prometheus Remote Storage extension 0.2.1 - https://github.com/timescale/pg_prometheus
#
# TODO:
# - Separate PostgreSQL, TimescaleDB and PgPrometheus into separate mutations
##

TMP_DIR=/tmp/bestiary/$(uuidgen -t)
sudo mkdir -p $TMP_DIR

# Download PGDG for PostgreSQL 11:
sudo yum install -y https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-7-x86_64/pgdg-centos11-11-2.noarch.rpm

# Exclude PostgreSQL from CentOS repos
sudo sed -i'.bak' -e 's/gpgkey.*/&\nexclude=postgresql\*/g' /etc/yum.repos.d/CentOS-Base.repo

# Install PostgreSQL 11
sudo yum -y install postgresql11 postgresql11-server postgresql11-devel postgresql11-contrib
sudo /usr/pgsql-11/bin/postgresql-11-setup initdb

# Install TimescaleDB
sudo tee /etc/yum.repos.d/timescale_timescaledb.repo <<EOL
[timescale_timescaledb]
name=timescale_timescaledb
baseurl=https://packagecloud.io/timescale/timescaledb/el/7/\$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/timescale/timescaledb/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
EOL

#sudo yum update -y
sudo yum install -y timescaledb-postgresql-11

# Enable TimescaleDB and PgPrometheus extensions
# Allow external connections
# sudo timescaledb-tune
# https://github.com/timescale/timescaledb-tune
sudo sed -i.bak \
         -e "s/shared_preload_libraries.*/#&\nshared_preload_libraries = 'timescaledb,pg_prometheus'/g" \
         -e "s/listen_addresses.*/#&\nlisten_addresses = '*'/g" \
         /var/lib/pgsql/11/data/postgresql.conf

# TODO: Test scram-sha-256
sudo sed -i.bak \
         -e "s/ident/md5/g" \
         -e "s/127\.0\.0\.1\/32/0.0.0.0\/0/g" \
         -e "s/::1\/128/::\/0/g" \
         /var/lib/pgsql/11/data/pg_hba.conf

# Build Prometheus Remote Storage
PG_PROM_VERSION=0.2.1
PG_PROM_DIST=$PG_PROM_VERSION.tar.gz
PG_PROM_BUILD_DIR=$TMP_DIR/pg_prometheus
sudo curl --create-dirs -L -o $TMP_DIR/$PG_PROM_DIST https://github.com/timescale/pg_prometheus/archive/$PG_PROM_DIST
sudo mkdir -p $PG_PROM_BUILD_DIR
sudo tar -xzf $TMP_DIR/$PG_PROM_DIST -C $PG_PROM_BUILD_DIR --strip-components=1

# START Workaround (or is it expected?) for:
#   "make: /opt/rh/llvm-toolset-7/root/usr/bin/clang: Command not found"
sudo yum -y --enablerepo=extras install centos-release-scl
sudo rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum -y --enablerepo=epel install llvm5.0 
sudo yum -y install devtoolset-7 llvm-toolset-7
sudo yum -y install patch
sudo tee $TMP_DIR/pg_prometheus.11.patch <<EOF
diff -c pg_prometheus/src/prom.c pg_prometheus_patch/src/prom.c
*** pg_prometheus/src/prom.c      2018-08-17 13:04:20.000000000 +0000
--- pg_prometheus_patch/src/prom.c        2019-03-23 21:43:29.000000000 +0000
***************
*** 404,410 ****
        TimestampTz ts = PG_GETARG_TIMESTAMPTZ(0);
        text       *name = PG_GETARG_TEXT_PP(1);
        float8          value = PG_GETARG_FLOAT8(2);
!       Jsonb      *jb = PG_GETARG_JSONB(3);

        char       *metric_name = text_to_cstring(name);
        PrometheusJsonbParseCtx ctx = {0};
--- 404,414 ----
        TimestampTz ts = PG_GETARG_TIMESTAMPTZ(0);
        text       *name = PG_GETARG_TEXT_PP(1);
        float8          value = PG_GETARG_FLOAT8(2);
!       #ifdef PG_GETARG_JSONB_P
!           Jsonb   *jb = PG_GETARG_JSONB_P(3);
!       #else
!           Jsonb   *jb = PG_GETARG_JSONB(3);
!       #endif

        char       *metric_name = text_to_cstring(name);
        PrometheusJsonbParseCtx ctx = {0};
EOF
cd $TMP_DIR
# TODO: Fix this, patch didn't apply (probably because of spaces, line breaks, etc.)
sudo patch -p0 -i pg_prometheus.11.patch
# END Workaround
cd $PG_PROM_BUILD_DIR
sudo make PG_CONFIG=/usr/pgsql-11/bin/pg_config
sudo make PG_CONFIG=/usr/pgsql-11/bin/pg_config install 

# Start PostgreSQL
sudo systemctl enable postgresql-11
sudo systemctl start postgresql-11
sudo systemctl status postgresql-11

# Pass through Packer's ENV variables
# https://www.packer.io/docs/provisioners/shell.html#environment_vars
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$POSTGRESQL_PASSWORD';"

# Configure Prometheus Remote storage
sudo -u postgres psql -c "CREATE ROLE prometheus WITH LOGIN PASSWORD '$POSTGRESQL_PASSWORD';"
sudo -u postgres psql -c "CREATE DATABASE prometheus WITH OWNER prometheus;"
sudo -u postgres psql -d "prometheus" -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"
sudo -u postgres psql -d "prometheus" -c "CREATE EXTENSION IF NOT EXISTS pg_prometheus;"
export PGPASSWORD="$POSTGRESQL_PASSWORD"; psql -h localhost -U prometheus -c "SELECT create_prometheus_table('metrics',use_timescaledb=>true);"
# sudo -u postgres psql -d "prometheus" -c "SELECT create_prometheus_table('metrics',use_timescaledb=>true);"
sudo -u postgres psql -d "prometheus" -c "GRANT ALL ON SCHEMA prometheus TO prometheus;"
sudo -u postgres psql -d "prometheus" -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA prometheus TO prometheus;"
# pg_prometheus extension creates a 'prometheus' schema automatically during the init procedure... 
# Since it creates it with default permissions, we need to set it to the current user (see above)
# and run it again, to complete the init procedure
export PGPASSWORD="$POSTGRESQL_PASSWORD"; psql -h localhost -U prometheus -c "SELECT create_prometheus_table('metrics',use_timescaledb=>true);"

# TODO: Add prometheus-postgresql-adapter

# Clean up tmp files
sudo rm -rf $TMP_DIR
