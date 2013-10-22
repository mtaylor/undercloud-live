#!/bin/bash

set -eux

export TRIPLEO_ROOT=/opt/stack/images

source /etc/sysconfig/undercloud-live-config
source /etc/sysconfig/undercloudrc

export CPU=${NODE_CPU:-1}
export MEM=${NODE_MEM:-2048}
export DISK=${NODE_DISK:-20}
export ARCH=${NODE_ARCH:-amd64}

deploy_kernel=$TRIPLEO_ROOT/deploy-ramdisk.kernel
deploy_ramdisk=$TRIPLEO_ROOT/deploy-ramdisk.initramfs
deploy_kernel_id=$(glance image-create --name bm-deploy-kernel --public \
    --disk-format aki < "$deploy_kernel" | awk ' / id / {print $4}')
deploy_ramdisk_id=$(glance image-create --name bm-deploy-ramdisk --public \
    --disk-format ari < "$deploy_ramdisk" | awk ' / id / {print $4}')

# While we can't mix hypervisors, having non-baremetal flavors will just
# confuse things.
nova flavor-delete m1.tiny || true
nova flavor-delete m1.small || true
nova flavor-delete m1.medium || true
nova flavor-delete m1.large || true
nova flavor-delete m1.xlarge || true

nova flavor-delete baremetal || true
nova flavor-create baremetal auto $MEM $DISK $CPU
nova flavor-key baremetal set "cpu_arch"="$ARCH" \
    "baremetal:deploy_kernel_id"="$deploy_kernel_id" \
    "baremetal:deploy_ramdisk_id"="$deploy_ramdisk_id"
