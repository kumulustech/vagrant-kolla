#!/bin/bash

. ~/open.rc

openstack flavor create --public  --id  1 --ram 256 --disk 1 --vcpus 1 m1.tiny
openstack flavor create --public  --id  3 --ram 512 --disk 1 --vcpus 1 m1.small
openstack flavor create --public  --id  5 --ram 1024 --disk 4 --vcpus 2 m1.medium

