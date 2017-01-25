#!/bin/bash

. ~/open.rc

nova boot --flavor m1.tiny --image cirros --nic net-id=`neutron net-list | awk '/ private / {print $2}'` --poll cirros
sleep 5
floating_ip=`neutron floatingip-create public | awk '/ floating_ip_address / {print $4}'`
sleep 5
nova floating-ip-associate cirros ${floating_ip}
echo ""
echo "Cirros instance should be available on ${floating_ip}"
echo "try accessing via ssh from controller: cirros@${floating_ip}"
echo "password is cubswin:)"
echo ""
