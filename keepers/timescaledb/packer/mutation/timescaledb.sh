#!/bin/bash

# Download PGDG for PostgreSQL 11:
sudo yum install -y https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-7-x86_64/pgdg-centos11-11-2.noarch.rpm

# Exclude PostgreSQL from CentOS repos
sudo sed -i'.bak' -e 's/gpgkey.*/&\nexclude=postgresql\*/g' /etc/yum.repos.d/CentOS-Base.repo

# Install PostgreSQL 11
sudo yum -y install postgresql11 postgresql11-server
sudo /usr/pgsql-11/bin/postgresql-11-setup initdb

# Install TimescaleDB
sudo cat > /etc/yum.repos.d/timescale_timescaledb.repo <<EOL
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

sudo yum update -y
sudo yum install -y timescaledb-postgresql-11

# Enable TimescaleDB extension and allow external connections
# sudo timescaledb-tune
# NOTE: This would disable every other shared library (as it just comments-out the previous value)
sudo sed -i.bak \
         -e "s/shared_preload_libraries.*/#&\nshared_preload_libraries = 'timescaledb'/g" \
         -e "s/listen_addresses.*/#&\nlisten_addresses = '*'/g" \
         /var/lib/pgsql/10/data/postgresql.conf
# TODO: Test scram-sha-256
sudo sed -i.bak \
         -e "s/ident/md5/g" \
         -e "s/127\.0\.0\.1\/32/0.0.0.0\/0/g" \
         -e "s/::1\/128/::\/0/g" \
         /var/lib/pgsql/10/data/pg_hba.conf

sudo systemctl enable postgresql-11
sudo systemctl start postgresql-11

# Pass through Packer's ENV variables
# https://www.packer.io/docs/provisioners/shell.html#environment_vars
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$POSTGRESQL_PASSWORD';"
# TODO: Execute this within database
# sudo -u postgres psql -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"

# TODO: Add pg_prometheus
# TODO: Add prometheus-postgresql-adapter
