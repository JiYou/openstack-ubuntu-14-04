#!/bin/bash
#!/bin/bash

set -e

# Step 1: register cirros

# Step 2: create network.
neutron router-create router01
Router_ID=`neutron router-list | grep router01 | awk '{ print $2 }'`
neutron net-create int_net
neutron subnet-create \
    --gateway 192.168.100.1 --dns-nameserver 8.8.8.8 int_net 192.168.100.0/24

Int_Subnet_ID=`neutron net-list | grep int_net | awk '{ print $6 }'`
neutron router-interface-add $Router_ID $Int_Subnet_ID

neutron net-create ext_net --router:external=True

neutron subnet-create ext_net \
--allocation-pool start=10.0.2.150,end=10.0.2.254 \
--gateway 10.0.2.1 --dns-nameserver 8.8.8.8 10.0.2.0/24


Ext_Net_ID=`neutron net-list | grep ext_net | awk '{ print $2 }'`
neutron router-gateway-set $Router_ID $Ext_Net_ID
Int_Net_ID=`neutron net-list | grep int_net | awk '{ print $2 }'`

exit 0
# Step 3: Create  VM
nova boot --flavor 1 --image cirros.img --security_group default --nic net-id=$Int_Net_ID Ubuntu_Trusty

# Ste p4: Create floating ip
neutron floatingip-create ext_net
Device_ID=`nova list | grep Ubuntu_Trusty | awk '{ print $2 }'`
Port_ID=`neutron port-list -- --device_id $Device_ID | grep 192.168.100.2 | awk '{ print $2 }'`
Floating_ID=`neutron floatingip-list | grep 10.0.2.101 | awk '{ print $2 }'`
neutron floatingip-associate $Floating_ID $Port_ID
neutron floatingip-show $Floating_ID
