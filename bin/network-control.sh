#!/bin/bash

set -eux

if [ -f /opt/stack/undercloud-live/.network-control ]; then
    exit
fi

source /opt/stack/undercloud-live/bin/common.sh
source /etc/sysconfig/undercloud-live-config

source /etc/sysconfig/undercloudrc

# Find the admin tenant.
TENANT_ID=$(keystone tenant-list | grep ' admin ' | awk '{print $2}')

neutron net-create --tenant-id $TENANT_ID ctlplane --shared --provider:network_type flat --provider:physical_network ctlplane
neutron subnet-create --tenant-id $TENANT_ID ctlplane 192.0.2.0/24

sudo touch /opt/stack/undercloud-live/.network-control
