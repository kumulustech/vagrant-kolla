#!/bin/bash

. ~/open.rc

name=${1:-test}
if [[ -z `openstack  keypair list --insecure | grep id_rsa >& /dev/null && echo 1` || `echo 0` ]] ; then
echo adding keypair
openstack  keypair create --public-key ~/.ssh/id_rsa.pub id_rsa --insecure
fi

echo adding server
openstack  server create --flavor 5 --image xenial --nic net-id=private --key-name id_rsa ${name}  --insecure
echo grabbing a floating IP
floating_ip=`openstack  floating ip create public --insecure | awk '/ floating_ip_address / {print $4}'`
echo got ${floating_ip} sleeping for sync
sleep 15
openstack  server add floating ip ${name} ${floating_ip} --insecure
echo "A Xenial instance should be available on ${floating_ip}"
echo "try accessing via ssh from controller:"
echo "                 ubuntu@${floating_ip}"
