#!/bin/bash

apt-get update
apt-get dist-upgrade -y
#apt-get install curl \
#    linux-image-extra-$(uname -r) \
#    linux-image-extra-virtual -y
apt-get install \
    python-pip \
    vim \
    htop \
    python-dev \
    python-netaddr \
    python-openstackclient \
    python-neutronclient \
    libffi-dev \
    libssl-dev \
    gcc \
    apt-transport-https \
    ca-certificates \
    bridge-utils -y

apt-get install apt-transport-https ca-certificates -y
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
deb https://apt.dockerproject.org/repo ubuntu-xenial main
echo 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install docker-engine=1.12.6-0~ubuntu-xenial -y

apt-get purge lxc lxd -y
mkdir -p /etc/systemd/system/docker.service.d
if [[ -z $(grep shared /etc/systemd/system/docker.service.d/kolla.conf) ]]; then
tee /etc/systemd/system/docker.service.d/kolla.conf <<-EOF
[Service]
MountFlags=shared
EOF
fi

systemctl daemon-reload
systemctl enable docker
systemctl restart docker

pip install -U pip
pip install ansible==2.1.2.0
pip install docker-py

if [[ $(ip l | grep team) ]]; then
NETWORK_INTERFACE="team0"
NEUTRON_INTERFACE="team0:0"
elif [[ $(ip l | grep bond) ]]; then
NETWORK_INTERFACE="bond0"
NEUTRON_INTERFACE="bond0:0"
elif [[ $(ip l | grep enp0s8) ]]; then
NETWORK_INTERFACE="enp0s8"
NEUTRON_INTERFACE="enp0s9"
ifup enp0s9
else
echo "Can't figure out network interface, please manually edit"
exit 1
fi
NEUTRON_PUB="$(ip -4 addr show ${NEUTRON_INTERFACE} | grep "${NEUTRON_INTERFACE}" | head -1 |awk '{print $2}' | cut -d/ -f1)"
BASE="$(echo ${NEUTRON_PUB} | cut -d. -f 1,2,3)"

ADDRESS="$(ip -4 addr show ${NETWORK_INTERFACE} | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"

if [ `egrep -c 'vmx|svm|0xc0f' /proc/cpuinfo` == '0' ] ;then
if [ ! -f /etc/kolla/config/nova/nova-compute.conf ]; then
mkdir -p /etc/kolla/config/nova/
tee > /etc/kolla/config/nova/nova-compute.conf <<-EOF
[libvirt]
virt_type=qemu
EOF
fi
fi
