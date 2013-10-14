#!/bin/bash

set -eux

source /opt/stack/undercloud-live/bin/common.sh
source /etc/sysconfig/undercloud-live-config

# The commands in this script require a running, configured cloud.

if [ -f /opt/stack/undercloud-live/.setup ]; then
    exit
fi

sudo cp /root/stackrc /etc/sysconfig/undercloudrc
source /etc/sysconfig/undercloudrc

# Ensure keystone is up before continuing on.
# Waits for up to 2 minutes.
wait_for 12 10 sudo systemctl status keystone

# Because keystone just still isn't up yet...
sleep 20

# Make sure we have the latest $PATH set.
source /etc/profile.d/tripleo-incubator-scripts.sh

sudo mkdir -p /root/.ssh
sudo chmod 0700 /root/.ssh
sudo bash -c "cat /home/$USER/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys"

init-keystone -p unset unset \
    $UNDERCLOUD_CONTROL_IP admin@example.com root@$UNDERCLOUD_CONTROL_IP

setup-endpoints $UNDERCLOUD_CONTROL_IP --glance-password unset \
    --heat-password unset \
    --neutron-password unset \
    --nova-password unset

keystone role-create --name heat_stack_user

# Adds default ssh key to nova
/opt/stack/tripleo-incubator/scripts/user-config

sudo touch /opt/stack/undercloud-live/.setup
