#!/bin/bash -xe
##
# Installs OpenJDK 12 - https://adoptopenjdk.net/
#
# TODO: Add openj9 builds?
##

sudo tee -a /etc/yum.repos.d/adoptopenjdk.repo <<EOF
[AdoptOpenJDK]
name=AdoptOpenJDK
baseurl=http://adoptopenjdk.jfrog.io/adoptopenjdk/rpm/centos/7/$(uname -m)
enabled=1
gpgcheck=1
gpgkey=https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public
EOF

# Install OpenJDK
sudo yum -y install adoptopenjdk-12-hotspot

# TODO: Check if this might be needed.
# sudo alternatives --config javac

# Show Version
java -version
