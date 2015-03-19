#!/bin/bash

set -e
set -o xtrace

cd /root/
if [[ `service mysql status | grep running | wc -l` -eq 0 ]]; then
	service mysql start
fi

service rabbitmq-server start
service keystone start
source keyrc
keystone user-list

./swift-proxy.sh
./swift-storage.sh
sleep 20
source swiftrc
swift stat

./glance.sh
sleep 20
glance index

./quantum.sh
./quantum-agent.sh
sleep 3
quantum net-list

./cinder-api.sh
./cinder-volume.sh

./nova-api.sh
./nova-compute.sh

./dashboard.sh

virsh list --all | grep instan  | grep -v running | awk '{print $2}' | xargs -i virsh start {}

set +o xtrace
