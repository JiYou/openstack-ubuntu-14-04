#!/bin/bash

set -e
set -o xtrace

#---------------------------------------------
# Set up Env.
#---------------------------------------------

TOPDIR=$(cd $(dirname "$0") && pwd)
source $TOPDIR/localrc
source $TOPDIR/tools/function
TEMP=`mktemp`; rm -rfv $TEMP >/dev/null; mkdir -p $TEMP;


#---------------------------------------------
# Get Password
#---------------------------------------------

set_password MYSQL_ROOT_PASSWORD


#---------------------------------------------
# Install mysql by apt-get
#---------------------------------------------

DEBIAN_FRONTEND=noninteractive \
apt-get --option "Dpkg::Options::=--force-confold" --assume-yes \
install -y --force-yes openssh-server mysql-server

#---------------------------------------------
# Set root's password
#---------------------------------------------

if [[ `cat /etc/mysql/my.cnf | grep "0.0.0.0" | wc -l` -eq 0 ]]; then
    mysqladmin -uroot password $MYSQL_ROOT_PASSWORD
fi
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
service mysql restart


#---------------------------------------------
# Give root's right
#---------------------------------------------
mysql -uroot -p$MYSQL_ROOT_PASSWORD  -e "use mysql; delete from user where user=''; flush privileges;"
mysql -uroot -p$MYSQL_ROOT_PASSWORD  -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' identified by '$MYSQL_ROOT_PASSWORD'; FLUSH PRIVILEGES;"
mysql -uroot -p$MYSQL_ROOT_PASSWORD  -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' identified by '$MYSQL_ROOT_PASSWORD'  WITH GRANT OPTION; FLUSH PRIVILEGES;"
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e  "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' identified by '$MYSQL_ROOT_PASSWORD'; FLUSH PRIVILEGES;"
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' identified by '$MYSQL_ROOT_PASSWORD'  WITH GRANT OPTION; FLUSH PRIVILEGES;"
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "flush privileges;"

service mysql restart

set +o xtrace
