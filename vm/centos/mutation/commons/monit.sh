#!/bin/bash -xe
##
# Installs monit - https://mmonit.com/monit/
#
# Mutation required:
# - base.sh
##
# Install Monit
sudo yum -y install monit

# Enable monit
sudo systemctl enable monit
sudo systemctl restart monit