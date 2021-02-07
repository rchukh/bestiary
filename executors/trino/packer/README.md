# Trino Packer configuration

## Overview

Packer configuration for [Trino](https://Trino.io).

## Configurations

- [Bestiary Base Linux VM](https://github.com/rchukh/bestiary/tree/master/vm/centos)
- [Trino 351](https://trino.io/docs/current/release/release-351.html)
- Monit over SysVinit that comes with Trino
- [Amazon Corretto 11](https://aws.amazon.com/corretto/) as JVM
- Prometheus JMX Exporter (Port 8081)

## Variables

| Variable         | Required | Description                      |                                          Default |
| ---------------- | :------: | -------------------------------- | -----------------------------------------------: |
| gcp_account_file |   yes    | Path to GCP Service Account file | `GOOGLE_CLOUD_KEYFILE_JSON` environment variable |
| gcp_project_id   |   yes    | GCP Project Id                   |                                                  |
| gcp_zone         |    no    | GCP Zone                         |                                 `europe-west1-d` |

## Build

Provide the required variables and build the image:

```sh
packer build \
   -var 'gcp_project_id=my_project' \
   gcloud.json
```
