#!/bin/bash

. ~/open.rc

set -ex
# Create project
openstack project create obs
# Create users
user() {
project=${1:-obs}
user=${2}
password=${3}
openstack user create $user --project $project --password $password
openstack role add --user $user --project $project _member_
openstack role add --user $user --project $project admin
openstack role add --user $user --project $project heat_stack_owner

}

user obs phil 'ChangeMe'
user obs thomas 'ChangeMe'
user obs robert 'ChangeMe'
user obs tom 'ChangeMe'
user obs chad 'ChangeMe'
# Associate user with project
# Create flavor
openstack  flavor create --id 4 --ram 8192 --disk 30 --vcpus 4 --private --project obs irg.small
openstack  flavor create --id 8 --ram 16384 --disk 60 --vcpus 8 --private --project obs irg.medium
openstack  flavor create --id 10 --ram 32768 --disk 120 --vcpus 16 --private --project obs irg.large 

# Create network and security group information

openstack  network create obs --project obs
openstack  subnet create obs --subnet-range 192.168.100.0/24 --project obs --dns-nameserver 8.8.8.8 --dns-nameserver 8.8.4.4 --dhcp --network obs 


openstack  router create obs-router --project obs

openstack  router set obs-router --external-gateway public 
openstack  router add subnet obs-router obs 

# Adjust the default security group.  This is not good practice
default_group=`openstack  security group list --project obs  | awk '/ default / {print $2}'`
openstack  security group rule create --ingress --dst-port 22 --protocol tcp --remote-ip 0.0.0.0/0 ${default_group}  
openstack  security group rule create --ingress --dst-port 80 --protocol tcp --remote-ip 0.0.0.0/0 ${default_group}  
openstack  security group rule create --ingress --dst-port 443 --protocol tcp --remote-ip 0.0.0.0/0 ${default_group}  
openstack  security group rule create --ingress --protocol icmp --remote-ip 0.0.0.0/0 ${default_group}  


