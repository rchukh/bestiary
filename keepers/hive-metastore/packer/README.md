# Hive Metastore Packer configuration

## Overview

Packer configuration of [Hive Metastore](https://cwiki.apache.org/confluence/display/Hive/AdminManual+Metastore+Administration).

## Configurations

- [Bestiary Base Linux 2.1 (CentOS 7)](https://github.com/rchukh/bestiary/blob/master/vm/centos/CHANGELOG.md)
- [Amazon Corretto 1.8](https://aws.amazon.com/corretto/) as JVM
- Hive Metastore 2.3.5
- Prometheus Node Exporter (Port 9100)
- Prometheus JMX Exporter (Port 8081)

## Variables

| Variable            | Required | Description                                               |                                          Default |
| ------------------- | :------: | --------------------------------------------------------- | -----------------------------------------------: |
| gcp_account_file    |   yes    | Path to GCP Service Account file                          | `GOOGLE_CLOUD_KEYFILE_JSON` environment variable |
| gcp_project_id      |   yes    | GCP Project Id                                            |                                                  |
| gcp_zone            |    no    | GCP Zone                                                  |                                 `europe-west1-d` |

## Build

Provide the require variables and build the image:

```sh
packer build \
   -var 'gcp_project_id=my_project' \
   gcloud.json
```

## Deployment

The image requires additional steps during deployment process, such as database preparation and misc Hive Metastore configuration.

See `../terraform` for deployment details. 