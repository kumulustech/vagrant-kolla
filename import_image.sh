#! /bin/bash

source ~/open.rc
if [ ! -f xenial.img ]; then
curl https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img > xenial.img
fi
#curl http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img > cirros-0.3.4-x86_64-disk.img
openstack  image create --container-format bare --disk-format qcow2 --min-disk 2 --min-ram 1000 --public --file xenial.img xenial --insecure
