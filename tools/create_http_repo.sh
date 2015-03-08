#!/bin/bash

#set -e
set -o xtrace

#---------------------------------------------------
# Prepare ENV
#---------------------------------------------------

TOPDIR=$(cd $(dirname "$0") && pwd)
TEMP=`mktemp`; rm -rfv $TEMP >/dev/null;mkdir -p $TEMP;

old_dir=`pwd`
cnt=`ls $TOPDIR | grep tools | wc -l`
if [[ $cnt -gt 0 ]]; then
    cd `ls -l tools | awk '{print $11}'`
    TOPDIR=`pwd`
fi

mkdir -p /var/www/html/
[[ ! -e /var/www/pip ]] && cp -rf $TOPDIR/../packages/pip /var/www/html/

cd /var/www/html/pip
cp -rf Routes/ routes
cp -rf SQLAlchemy/ sqlalchemy

cd $old_dir

#---------------------------------------------------
# Install apt packages
#---------------------------------------------------

apt-get install -y --force-yes openssh-server build-essential git \
python-dev python-setuptools python-pip libxml2-dev \
libxslt1.1 libxslt1-dev libgnutls-dev libnl-3-dev \
python-virtualenv libnspr4-dev libnspr4 pkg-config \
apache2 unzip nfs-kernel-server nfs-common portmap


[[ -e /usr/include/libxml ]] && rm -rf /usr/include/libxml
ln -s /usr/include/libxml2/libxml /usr/include/libxml
[[ -e /usr/include/netlink ]] && rm -rf /usr/include/netlink
ln -s /usr/include/libnl3/netlink /usr/include/netlink

cd $old_dir
cnt=`cat /etc/exports | grep html | wc -l`
if [[ $cnt -eq 0 ]]; then
    echo "/var/www/html *(rw,sync,no_root_squash)" >> /etc/exports
fi
chmod a+r -R /var/www/html/
chmod a+w -R /var/www/html/
/etc/init.d/portmap restart
/etc/init.d/nfs-kernel-server restart

set +o xtrace
