# Control Environment

## Overview

The main goal is to provide dedicated resources for common infrastructure, so that the evaluation tools are (as much as possible) separated from the infrastructure that is evaluated.

## Components

- Benchmark
  - Benchto Driver
  - Benchto Service
- Monitoring / Visualization
  - Prometheus
  - Grafana
- Storage
  - PostgreSQL 11 (for Benchto Service, Grafana and Prometheus backend storage)


## Decisions

### PostgreSQL

PostgreSQL is installed on the VM and is not used as a service (e.g. CloudSQL), due to:

- Сustom extensions (e.g. TimescaleDB, pg_prometheus)
- Possibility to use the latest version
- Smaller cost footprint
- Relaxed requirements since this is a throw-away environment (e.g. no need for HA here).
