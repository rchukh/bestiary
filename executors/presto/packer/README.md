# Presto Packer configuration
## Overview

Packer configuration of [PrestoSQL](https://prestosql.io).

## Configurations

- CentOS 7
- Presto [305](https://prestosql.io/docs/current/release/release-305.html)
- Mainline Kernel from elrepo with TCP BBR as default
- Monit over SysVinit that comes with Presto
- Amazon Corretto 1.8 as JVM
- Prometheus Node Exporter (Port 9100)
- Prometheus JMX Exporter (Port 8081)

## Build

1. Change the `account_file` to match your Google Cloud credential file and `project_id` to match your Google Cloud Project.
2. Build the image

    ```sh
    packer build gcloud.json
    ```
