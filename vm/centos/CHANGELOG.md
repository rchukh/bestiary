# CHANGELOG

## Unreleased

Updated:

- Node Exporter to 0.18.1

## [2.0.0](https://app.vagrantup.com/rchukh/boxes/bestiary-centos/versions/2.0.0)

Breaking Changes:

- Removed Java Amazon Corretto (no need in the base image, can be installed from mutations when needed)

Added:

- New packages: zip, unzip

## [1.0.0](https://app.vagrantup.com/rchukh/boxes/bestiary-centos/versions/1.0.0)

Initial release.

Based on [centos/7, version 1902.01](https://app.vagrantup.com/centos/boxes/7/versions/1902.01)

Notable Changes:

- [Mainline branch](https://www.kernel.org/) Linux Kernel - 5.0.10
- [TCP BBR](https://medium.com/google-cloud/tcp-bbr-magic-dust-for-network-performance-57a5f1ccf437)
- Prometheus [Node Exporter 0.17](https://github.com/prometheus/node_exporter/releases/tag/v0.17.0)
- [Monit 5.25.1](https://mmonit.com/monit/changes/)
- Java [Amazon Corretto 1.8.0_212.b04-2](https://aws.amazon.com/corretto/) 