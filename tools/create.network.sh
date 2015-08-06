#!/bin/bash
#!/bin/bash

set -e

# register cirros

# 理解网络功能，重要！！！！！
# 这里先建一个router
neutron router-create router01

# 这里查询刚刚建好的router的ID
Router_ID=`neutron router-list | grep router01 | awk '{ print $2 }'`

# 这里建一个内部网络。这个内部网络与真实的物理机网络没有任何关系，是虚拟的。
# 但是网关，我们仍然习惯性的写成xxxx.1，采用默认的最好，不容易出问题。
neutron net-create int_net
neutron subnet-create \
    --gateway 192.168.100.1 --dns-nameserver 8.8.8.8 int_net 192.168.100.0/24
# 得到内部网络的ID号。
Int_Subnet_ID=`neutron net-list | grep int_net | awk '{ print $6 }'`
# 给这个内部网络添加router.
neutron router-interface-add $Router_ID $Int_Subnet_ID


# 这里再创建一个外部网络，这个外部网络是与真实的物理网络对应的。
neutron net-create ext_net --router:external=True

# 我从物理机的交换机那里向网管要的一段IP地址，就是150到254。
# 所以我这里必须要照物理网络来配置。并且要求网管在物理环境上做好相应的配置。
# 这里的网关什么的，都是真实的网关。
neutron subnet-create ext_net \
--allocation-pool start=10.0.2.150,end=10.0.2.254 \
--gateway 10.0.2.1 --dns-nameserver 8.8.8.8 10.0.2.0/24

# 这里拿到我创建好的外部网络的ID。这个ID存于OpenStack的数据。
Ext_Net_ID=`neutron net-list | grep ext_net | awk '{ print $2 }'`

# 把router添加到外部网络中，添加成功之后，这个router会在外部网络中占用一个IP。
# 比如将192.168.100.1 与10.0.2.151捆绑好。在前面创建的内网的VM要上网的时候，
# 都从网关(192.168.100.1)出去时，openvswitch会自动把192.168.100.1处理为10.0.2.151（物理网络IP）的请求，
# 从而实现了上网。
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
