#!/bin/bash

set -e
set -o xtrace

#---------------------------------------------------
# Set up global ENV
#---------------------------------------------------


TOPDIR=$(cd $(dirname "$0") && pwd)
TEMP=`mktemp`;
rm -rfv $TEMP >/dev/null;
mkdir -p $TEMP;
source $TOPDIR/localrc
source $TOPDIR/tools/function
DEST=/opt/stack/

#---------------------------------------------------
#  Your Configurations.
#---------------------------------------------------

BASE_SQL_CONN=mysql://$MYSQL_CINDER_USER:$MYSQL_CINDER_PASSWORD@$MYSQL_HOST

unset OS_USERNAME
unset OS_AUTH_KEY
unset OS_AUTH_TENANT
unset OS_STRATEGY
unset OS_AUTH_STRATEGY
unset OS_AUTH_URL
unset SERVICE_TOKEN
unset SERVICE_ENDPOINT
unset http_proxy
unset https_proxy
unset ftp_proxy

KEYSTONE_AUTH_HOST=$KEYSTONE_HOST
KEYSTONE_AUTH_PORT=35357
KEYSTONE_AUTH_PROTOCOL=http
KEYSTONE_SERVICE_HOST=$KEYSTONE_HOST
KEYSTONE_SERVICE_PORT=5000
KEYSTONE_SERVICE_PROTOCOL=http
SERVICE_ENDPOINT=http://$KEYSTONE_HOST:35357/v2.0

#---------------------------------------------------
# Clear Front installation
#---------------------------------------------------

DEBIAN_FRONTEND=noninteractive \
apt-get --option \
"Dpkg::Options::=--force-confold" --assume-yes \
install -y --force-yes mysql-client

nkill cinder-volume
[[ -d $DEST/cinder ]] && cp -rf $TOPDIR/openstacksource/cinder/etc/cinder/* $DEST/cinder/etc/cinder/

############################################################
#
# Install some basic used debs.
#
############################################################



apt-get install -y --force-yes openssh-server build-essential git \
python-dev python-setuptools python-pip \
libxml2-dev libxslt-dev tgt lvm2 \
unzip python-mysqldb mysql-client memcached openssl expect \
iputils-arping \
python-lxml kvm gawk iptables ebtables sqlite3 sudo kvm \
vlan curl socat python-mox python-migrate \
iscsitarget iscsitarget-dkms open-iscsi python-requests


service ssh restart

#---------------------------------------------------
# Copy source code to DEST Dir
#---------------------------------------------------

[[ ! -d $DEST ]] && mkdir -p $DEST
install_keystone
install_cinder


#################################################
#
# Change configuration file.
#
#################################################

mkdir -p /etc/cinder
old_dir=`pwd`

mkdir -p /tmp/sharedir_openstack/
if [[ `mount | grep sharedir_openstack | wc -l` -eq 0 ]]; then
    mount -t nfs 192.168.56.110:/var/www/html /tmp/sharedir_openstack/
fi

cp -rf /tmp/sharedir_openstack/cinder.tar.gz /tmp/cinder.tar.gz

cd /tmp/
tar zxf cinder.tar.gz
mkdir -p /etc/cinder/
cp -rf cinder/* /etc/cinder/
cd $old_dir



file=/etc/tgt/targets.conf
sed -i "/cinder/g" $file
echo "include /etc/tgt/conf.d/cinder.conf" >> $file
echo "include /opt/stack/data/cinder/volumes/*" >> $file
cp -rf /etc/cinder/cinder.conf /etc/tgt/conf.d/

############################################################
# Create the volume storage.
############################################################


pvcreate -ff $VOLUME_DISK
vgcreate cinder-volumes $VOLUME_DISK


############################################################
# Start up the services.
############################################################


cat <<"EOF" > /root/cinder-volume.sh
#!/bin/bash
nkill cinder-volume
mkdir -p /var/log/cinder
python /opt/stack/cinder/bin/cinder-volume --config-file /etc/cinder/cinder.conf>/var/log/cinder/cinder-volume.log 2>&1 &
EOF

chmod +x /root/cinder-volume.sh
/root/cinder-volume.sh
rm -rf /tmp/pip*
rm -rf /tmp/tmp*

set +o xtrace
