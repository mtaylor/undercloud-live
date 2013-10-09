#!/bin/bash

set -eux

source /opt/stack/undercloud-live/bin/common.sh
source /etc/sysconfig/undercloud-live-config

# This script needs to be rerun if you reboot the undercloud.

# wait_for 12 10 ls /var/run/libvirt/libvirt-sock

# sudo sed -i "s/bridge name='brbm'/bridge name='br-ctlplane'/" /opt/stack/tripleo-incubator/templates/brbm.xml
# /opt/stack/tripleo-incubator/scripts/setup-network
