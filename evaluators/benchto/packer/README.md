# Benchto Packer configuration

## Overview

Packer configuration of [Benchto](https://github.com/prestosql/benchto).

## Configurations

- CentOS 7
- [Mainline Kernel from elrepo](https://elrepo.org/tiki/kernel-ml) with TCP BBR as default
- Monit
- [Amazon Corretto 1.8](https://aws.amazon.com/corretto/) as JVM
- Prometheus Node Exporter (Port 9100)

## Variables

| Variable         | Required | Description                      |                                          Default |
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
