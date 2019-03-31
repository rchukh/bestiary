# Benchto Packer configuration

## Overview

Packer configuration of [Benchto](https://github.com/prestosql/benchto).

## Configurations

- CentOS 7
  - [Mainline Kernel from elrepo](https://elrepo.org/tiki/kernel-ml) with TCP BBR as default
- [Monit](https://mmonit.com/monit/)
- [Amazon Corretto 1.8](https://aws.amazon.com/corretto/) as JVM
- Prometheus Node Exporter (Port 9100)
- PostgreSQL 11
  - [TimescaleDB](https://github.com/timescale/timescaledb) extension
  - [pg_prometheus](https://github.com/timescale/pg_prometheus) extension with [PostgreSQL 11 patch](https://github.com/timescale/pg_prometheus/pull/36)
- Benchto Service 0.7
- Benchto Driver 0.7

## Variables

| Variable            | Required | Description                                               |                                          Default |
| ------------------- | :------: | --------------------------------------------------------- | -----------------------------------------------: |
| gcp_account_file    |   yes    | Path to GCP Service Account file                          | `GOOGLE_CLOUD_KEYFILE_JSON` environment variable |
| gcp_project_id      |   yes    | GCP Project Id                                            |                                                  |
| gcp_zone            |    no    | GCP Zone                                                  |                                 `europe-west1-d` |
| postgresql_password |    no    | PostgreSQL `postgres` user password                       |                                       `postgres` |
| benchto_db_create   |    no    | Autocreates benchto database on local PostgreSQL instance |                                           `true` |
| benchto_db          |    no    | Benchto database name                                     |                                        `benchto` |
| benchto_db_user     |    no    | Benchto database username                                 |                                       `postgres` |
| benchto_db_password |    no    | Benchto database user password                            |                                       `postgres` |

## Build

Provide the require variables and build the image:

```sh
packer build \
   -var 'gcp_project_id=my_project' \
   gcloud.json
```
