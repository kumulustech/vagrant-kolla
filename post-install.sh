#!/bin/bash
pip install -U python-openstackclient=3.14.2
hash -d openstack

if [[ $(ip l | grep team) ]]; then
NETWORK_INTERFACE="team0"
NEUTRON_INTERFACE="team0:0"
elif [[ $(ip l | grep bond) ]]; then
NETWORK_INTERFACE="bond0"
NEUTRON_INTERFACE="bond0:0"
elif [[ $(ip l | grep eno1) ]]; then
NETWORK_INTERFACE="eno1"
NEUTRON_INTERFACE="eno2"
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
#ADDRESS="$(ip -4 addr show ${NETWORK_INTERFACE} | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"
ADDRESS=53.255.81.251
VIP="${ADDRESS}"

tee > ~/open.rc <<EOF
#!/usr/bin/env bash
export OS_AUTH_URL=http://control.cloudsushi.io:5000/v3
export OS_PROJECT_NAME="admin"
export OS_USER_DOMAIN_NAME="Default"
unset OS_TENANT_ID
unset OS_TENANT_NAME
export OS_USERNAME="admin"
export OS_PASSWORD=$(cat /etc/kolla/passwords.yml | grep "keystone_admin_password" | awk '{print $2}')
export OS_REGION_NAME="RegionOne"
export OS_INTERFACE=public
export OS_IDENTITY_API_VERSION=3
EOF

bash ./import_image.sh

bash ./add_flavor.sh

#bash ./setup_network.sh ${BASE}
bash ./setup_network.sh

echo "Login using http://control.cloudsushi.io with default as domain,  admin as username, and $(cat /etc/kolla/passwords.yml | grep "keystone_admin_password" | awk '{print $2}') as password"
