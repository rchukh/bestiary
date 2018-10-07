#!/bin/bash

# Download PGDG for PostgreSQL 10:
sudo yum install -y https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/pgdg-centos10-10-2.noarch.rpm

# Exclude PostgreSQL from CentOS repos
sudo sed -i'.bak' -e 's/gpgkey.*/&\nexclude=postgresql\*/g' /etc/yum.repos.d/CentOS-Base.repo

# Install PostgreSQL 10
sudo yum -y install postgresql10-server postgresql10
sudo /usr/pgsql-10/bin/postgresql-10-setup initdb

# Install TimescaleDB 0.12
sudo yum install -y https://timescalereleases.blob.core.windows.net/rpm/timescaledb-0.12.1-postgresql-10-0.x86_64.rpm
# Enable TimescaleDB extension and allow external connections
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

sudo systemctl enable postgresql-10.service
sudo systemctl start postgresql-10.service

# TODO: This is just a default, move this somewhere
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'timescale';"


# TODO: Add pg_prometheus
# TODO: Add prometheus-postgresql-adapter
