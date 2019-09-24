#! /bin/bash

source ~/open.rc
if [ ! -f cirros.img ]; then
curl http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img > cirros.img
fi
openstack  image create --container-format bare --disk-format qcow2 --min-disk 1 --min-ram 256 --public --file cirros.img cirros-0.3.5-x86_64-disk --insecure
