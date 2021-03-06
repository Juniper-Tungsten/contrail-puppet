set -x
RETVAL=0
## TODO: Change arguments from positional to options
## virsh secret that is configured on all conmpute nodes.
virsh_secret=$1
## openstack ip address
## TODO: This should be server where rabbit-mq server is running 
openstack_ip=$2
## Number of OSDs configured by user. This is used to ensure that all OSDs
## came up. and avoid restarting cinder-volume without ceph cluster is 
## completely online
NUM_TARGET_OSD=$3
## internal_vip
INTERNAL_VIP=$4

#sed -i "s/^bind-address/#bind-address/" /etc/mysql/my.cnf
# configuration for cinder taken care by post_openstack.pp
#openstack-config --set /etc/cinder/cinder.conf DEFAULT sql_connection mysql://cinder:cinder@127.0.0.1/cinder
ceph osd crush tunables optimal

## configure ceph-rest-api 
echo ${INTERNAL_VIP}

if [ ${INTERNAL_VIP} != "" ]
then
  sed -i "s/app.run(host=app.ceph_addr, port=app.ceph_port)/app.run(host=app.ceph_addr, port=5006)/" /usr/bin/ceph-rest-api
  echo "editing 5006 port"
else
  sed -i "s/app.run(host=app.ceph_addr, port=app.ceph_port)/app.run(host=app.ceph_addr, port=5005)/" /usr/bin/ceph-rest-api
  echo "editing 5005 port"
fi

## Check if "ceph -s" is returing or it is waiting for other monitors to be up
timeout 10 ceph -s 

RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "ceph -s failed"
  exit 1
fi

## Check if all OSDs are up.
## TODO : break the command to check each command failure
NUM_CURR_OSD=` ceph -s | grep "osdmap" | awk '{printf $7}'`
echo "current-osd : ${NUM_CURR_OSD}, target: ${NUM_TARGET_OSD}"
if [ "x${NUM_CURR_OSD}" != "x${NUM_TARGET_OSD}" ]
then
   echo "not all OSDs are up"
   #exit 1
fi
. /etc/contrail/openstackrc 


cinder-manage db sync
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "cinder-manage db sync failed"
  exit 1
fi

## Ensure the services are configured to be restarted on system startup
chkconfig cinder-api on
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "chkconfig cinder-api on failed"
  exit 1
fi
chkconfig cinder-scheduler on
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "chkconfig cinder-scheduler on failed"
  exit 1
fi
chkconfig cinder-volume on
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "chkconfig cinder-volume on failed"
  exit 1
fi



## Restart the affected services
service ceph-rest-api restart
service cinder-volume restart
service cinder-api restart
service cinder-scheduler restart
service glance-api restart
service nova-api restart
service nova-conductor restart
service nova-scheduler restart
service libvirt-bin restart



## Check if ocs-block-disk is already created. create if not
cinder type-list | grep -q ocs-block-disk
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  cinder type-create ocs-block-disk
  RETVAL=$?
  if [ ${RETVAL} -ne 0 ] 
  then
    echo "cinder type-create ocs-block-disk failed"
    exit 1
  fi
fi


## Set the volume_backend_name to RBD. this causes cinder to talk to ceph
cinder type-key ocs-block-disk set volume_backend_name=RBD
RETVAL=$?
if [ ${RETVAL} -ne 0 ] 
then
  echo "cinder type-key ocs-block-disk set volume_backend_name=RBD failed"
  exit 1
fi


## restarting cinder-volume again, bcause we have set volume_backend_name 
service cinder-volume restart


