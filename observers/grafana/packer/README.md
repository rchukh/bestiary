# Grafana Packer configuration

## Overview

Packer configuration for [Grafana](https://grafana.com/).

## Configurations

- [Bestiary Base Linux VM](https://github.com/rchukh/bestiary/tree/master/vm/centos)
- [Grafana 6.2.2](https://github.com/grafana/grafana/blob/master/CHANGELOG.md#622-2019-06-05)

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
