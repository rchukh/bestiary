#!/bin/sh

sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
sudo rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
sudo yum upgrade -y
sudo yum install mc wget uuidgen -y

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
