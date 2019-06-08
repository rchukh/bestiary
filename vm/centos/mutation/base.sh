#!/bin/bash -xe

sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
sudo rpm -qa | grep -qw elrepo-release || sudo rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
sudo rpm -qa | grep -qw epel-release || sudo rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

sudo yum clean all
sudo yum upgrade -y
# Handy tools
# - util-linux for uuidgen
# - net-tools for netstat
sudo yum -y install mc wget util-linux net-tools zip unzip

# User file limits
sudo cp /etc/security/limits.conf /etc/security/limits.conf.bak
sudo tee -a /etc/security/limits.conf << 'EOF'
*    soft    nofile 65536
*    hard    nofile 65536
EOF

# Global file limits
sudo cp /etc/sysctl.conf /etc/sysctl.conf.bak
sudo tee -a /etc/sysctl.conf << 'EOF'
fs.file-max = 65536
EOF
sudo sysctl -p
