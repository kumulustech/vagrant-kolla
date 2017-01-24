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
    gawk \
    apt-transport-https \
    ca-certificates \
    bridge-utils -y

apt-get install apt-transport-https ca-certificates -y
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

echo 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install docker-engine=1.12.6-0~ubuntu-xenial -y

apt-get purge lxc lxd -y
pip install -U pip
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

pip install ansible==2.1.2.0
pip install docker-py

git clone https://github.com/openstack/kolla -b stable/newton /root/kolla/
pip install /root/kolla/

cp -r /usr/local/share/kolla/etc_examples/kolla /etc/

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

GLOBALS_FILE="/etc/kolla/globals.yml"
ADDRESS="$(ip -4 addr show ${NETWORK_INTERFACE} | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"

VIP="${ADDRESS}"

# expand bond0:0 address space to /25

sed -i "s/^kolla_internal_vip_address:.*/kolla_internal_vip_address: \"${VIP}\"/g" ${GLOBALS_FILE}
sed -i "s/^network_interface:.*/network_interface: \"${NETWORK_INTERFACE}\"/g" ${GLOBALS_FILE}
sed -i "s/^#network_interface:.*/network_interface: \"${NETWORK_INTERFACE}\"/g" ${GLOBALS_FILE}

if [[ -z $(grep neutron_bridge_name ${GLOBALS_FILE}) ]]; then
cat >> ${GLOBALS_FILE} <<EOF
enable_haproxy: "no"
enable_keepalived: "no"
enable_cinder: "yes"
kolla_base_distro: "ubuntu"
kolla_install_type: "source"
openstack_release: "3.0.0"
EOF
fi

sed -i "s/^#neutron_external_interface:.*/neutron_external_interface: \"${NEUTRON_INTERFACE}\"/g" ${GLOBALS_FILE}

if [ `egrep -c 'vmx|svm|0xc0f' /proc/cpuinfo` == '0' ] ;then
if [ ! -f /etc/kolla/config/nova/nova-compute.conf ]; then
mkdir -p /etc/kolla/config/nova/
tee > /etc/kolla/config/nova/nova-compute.conf <<-EOF
[libvirt]
virt_type=qemu
EOF
fi
fi

#kolla-build --base ubuntu --type source --tag 3.0.0

kolla-genpwd

sed -i "s/^keystone_admin_password:.*/keystone_admin_password: admin1/" /etc/kolla/passwords.yml

#./multinode.sh control node-1
#./multinode.sh control node-2

#ssh node-1 /root/debian-cmp.sh
#ssh node-2 /root/debian-cmp.sh

#kolla-ansible -i multinode prechecks
#if [ ! $? == 0 ]; then
#  echo prechecks failed
#  exit 1
#fi

#kolla-ansible -i multinode deploy
#if [ ! $? == 0 ]; then
#  echo deploy failed
#  exit 1
#fi
