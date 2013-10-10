#!/bin/bash

set -eu

TRIPLEO_ROOT=${TRIPLEO_ROOT:-""}

if [ -z "$TRIPLEO_ROOT" ]; then
    echo \$TRIPLEO_ROOT is not defined, it should be set to the path of tripleo-incubator
    echo If needed, git clone tripleo-incubator and define \$TRIPLEO_ROOT by running:
    echo git clone https://github.com/openstack/tripleo-incubator
    echo export \$TRIPLEO_ROOT=`pwd`/tripleo-incubator/
    exit
fi

export PATH=$TRIPLEO_ROOT/scripts:$PATH

export UNDERCLOUD_MACS=$(create-nodes $NODE_CPU $NODE_MEM $NODE_DISK $NODE_ARCH 2)
UNDERCLOUD_MACS=`echo $UNDERCLOUD_MACS | tr '\n' ' '`

echo 
echo \$UNDERCLOUD_MACS is "$UNDERCLOUD_MACS"
echo 
echo Add or modify the following line in /etc/sysconfig/undercloud-live-config on the control node:
echo export UNDERCLOUD_MACS=\"$UNDERCLOUD_MACS\"
