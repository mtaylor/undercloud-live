#!/bin/bash

set -eux

source /etc/sysconfig/undercloudrc
source /etc/sysconfig/undercloud-live-config

/opt/stack/tripleo-incubator/scripts/setup-overcloud-passwords -o
source tripleo-overcloud-passwords

heat stack-create -f /opt/stack/tripleo-heat-templates/overcloud.yaml \
    -P "AdminToken=${OVERCLOUD_ADMIN_TOKEN};AdminPassword=${OVERCLOUD_ADMIN_PASSWORD};CinderPassword=${OVERCLOUD_CINDER_PASSWORD};GlancePassword=${OVERCLOUD_GLANCE_PASSWORD};HeatPassword=${OVERCLOUD_HEAT_PASSWORD};NeutronPassword=${OVERCLOUD_NEUTRON_PASSWORD};NovaPassword=${OVERCLOUD_NOVA_PASSWORD};NovaComputeLibvirtType=${OVERCLOUD_LIBVIRT_TYPE}" \
    overcloud
