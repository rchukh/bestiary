# Bestiary Base Linux VM

Vagrant Cloud: [rchukh/bestiary-centos](https://app.vagrantup.com/rchukh/boxes/bestiary-centos)

## Overview

Base:

- Google Cloud CentOS 7 (gcloud.json config)
- Vagrant CentOS 1902.01 (vagrant.json config)

Notable Changes:

- [Mainline branch](https://www.kernel.org/) Linux Kernel
- [TCP BBR](https://medium.com/google-cloud/tcp-bbr-magic-dust-for-network-performance-57a5f1ccf437)
- Prometheus [Node Exporter](https://github.com/prometheus/node_exporter)
- [Monit](https://mmonit.com/monit/changes/)

## Build Vagrant Box (Local Development)

1. Build the box

    ```sh
    packer build vagrant.json
    ```

2. Add the box to the local Vagrant boxes (change the <NAME> to name the box)

    ```sh
    vagrant box add --name <NAME> output-vagrant/package.box
    ```

## Build GCP Image

### Variables

| Variable         | Required | Description                      |                                          Default |
| ---------------- | :------: | -------------------------------- | -----------------------------------------------: |
| gcp_account_file |   yes    | Path to GCP Service Account file | `GOOGLE_CLOUD_KEYFILE_JSON` environment variable |
| gcp_project_id   |   yes    | GCP Project Id                   |                                                  |
| gcp_zone         |    no    | GCP Zone                         |                                 `europe-west1-d` |

### Build

Provide the variables and build the image:

```sh
packer build -var 'gcp_project_id=my_project' gcloud.json
```
