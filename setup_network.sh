#!/bin/bash
#   Copyright 2016 Kumulus Technologies <info@kumul.us>
#   Copyright 2016 Robert Starmer <rstarmer@gmail.com>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.source ~/admin.rc

source ~/open.rc

tenant=`openstack project list -f csv --quote none --insecure | grep admin | cut -d, -f1`

openstack network create public --project admin --external --provider-network-type flat --provider-physical-network physnet1 --share --default --insecure
#if segmented network{vlan,vxlan,gre}: --provider:segmentation_id ${segment_id}
openstack subnet create public --subnet-range 147.75.89.128/27 --project admin --gateway 147.75.89.129 --allocation-pool start=147.75.89.130,end=147.75.89.158 --no-dhcp --network public --insecure
# if you need a specific route to get "out" of your public network: --host-route destination=10.0.0.0/8,nexthop=10.1.10.254

openstack  network create private --project admin --insecure
openstack  subnet create private --subnet-range 192.168.100.0/24 --project admin --dns-nameserver 8.8.8.8 --dns-nameserver 8.8.4.4 --dhcp --network private --insecure


openstack  router create pub-router --project admin --insecure

openstack  router set pub-router --external-gateway public --insecure
openstack  router add subnet pub-router private --insecure

# Adjust the default security group.  This is not good practice
default_group=`openstack  security group list --project admin --insecure | awk '/ default / {print $2}'`
openstack  security group rule create --ingress --dst-port 22 --protocol tcp --remote-ip 0.0.0.0/0 ${default_group}  --insecure
openstack  security group rule create --ingress --dst-port 80 --protocol tcp --remote-ip 0.0.0.0/0 ${default_group}  --insecure
openstack  security group rule create --ingress --dst-port 443 --protocol tcp --remote-ip 0.0.0.0/0 ${default_group}  --insecure
openstack  security group rule create --ingress --protocol icmp --remote-ip 0.0.0.0/0 ${default_group}  --insecure
