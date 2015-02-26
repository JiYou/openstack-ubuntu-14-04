#!/bin/bash

set -e

neutron router-create router01
Router_ID=`neutron router-list | grep router01 | awk '{ print $2 }'`
neutron net-create int_net 
neutron subnet-create \
	--gateway 192.168.100.1 --dns-nameserver 192.168.0.14 int_net 192.168.100.0/24

Int_Subnet_ID=`neutron net-list | grep int_net | awk '{ print $6 }'`
neutron router-interface-add $Router_ID $Int_Subnet_ID

neutron net-create ext_net --router:external=True

neutron subnet-create ext_net \
--allocation-pool start=192.168.0.100,end=192.168.0.254 \
--gateway 192.168.0.1 --dns-nameserver 192.168.0.14 192.168.0.0/24


Ext_Net_ID=`neutron net-list | grep ext_net | awk '{ print $2 }'` 
neutron router-gateway-set $Router_ID $Ext_Net_ID 
Int_Net_ID=`neutron net-list | grep int_net | awk '{ print $2 }'` 
