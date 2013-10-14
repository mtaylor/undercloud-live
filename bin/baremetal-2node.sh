#!/bin/bash

set -eux

source /etc/sysconfig/undercloud-live-config
source /etc/sysconfig/undercloudrc 

# The NODE_* variables have sane defaults, but we need to exit if
# $UNDERCLOUD_MACS is not defined.
if [ -z "$UNDERCLOUD_MACS" ]; then
    echo \$UNDERCLOUD_MACS must be defined
    exit 1
fi

TRIPLEO_ROOT=/opt/stack/images setup-baremetal $NODE_CPU $NODE_MEM $NODE_DISK $NODE_ARCH "$UNDERCLOUD_MACS" undercloud-leaf
