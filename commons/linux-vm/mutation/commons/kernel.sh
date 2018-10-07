#!/bin/sh
##
# Updates to latest "mainline stable" Kernel (http://elrepo.org/tiki/kernel-ml).
# Enables Google BBR.
#
# Mutation required:
# - base.sh
##
sudo yum -y --enablerepo=elrepo-kernel install kernel-ml
sudo yum -y --enablerepo=elrepo-kernel swap kernel-headers -- kernel-ml-headers
sudo yum -y --enablerepo=elrepo-kernel swap kernel-tools-libs -- kernel-ml-tools-libs
sudo yum -y --enablerepo=elrepo-kernel install kernel-ml-tools
sudo yum -y --enablerepo=elrepo-kernel swap kernel-devel -- kernel-ml-devel
sudo yum -y remove kernel

sudo grub2-set-default 0
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# Enable BBR
echo 'net.core.default_qdisc=fq' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control=bbr' | sudo tee -a /etc/sysctl.conf

sudo sysctl -p
#sudo reboot
