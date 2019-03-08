# Presto Packer configuration

## Overview

Packer configuration of [PrestoSQL](https://prestosql.io).

## Configurations

- CentOS 7
- [Presto 305](https://prestosql.io/docs/current/release/release-305.html)
- [Mainline Kernel from elrepo](https://elrepo.org/tiki/kernel-ml) with TCP BBR as default
- Monit over SysVinit that comes with Presto
- [Amazon Corretto 1.8](https://aws.amazon.com/corretto/) as JVM
- Prometheus Node Exporter (Port 9100)
- Prometheus JMX Exporter (Port 8081)

## Variables

| Tables           | Required | Description                      |                                          Default |
| ---------------- | :------: | -------------------------------- | -----------------------------------------------: |
| gcp_account_file |   yes    | Path to GCP Service Account file | `GOOGLE_CLOUD_KEYFILE_JSON` environment variable |
| gcp_project_id   |   yes    | GCP Project Id                   |                                                  |
| gcp_zone         |    no    | GCP Zone                         |                                 `europe-west1-d` |

## Build

Provide the require variables and build the image:

```sh
packer build \
   -var 'gcp_project_id=my_project' \
   gcloud.json
```
