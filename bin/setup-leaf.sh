#!/bin/bash

set -eux

source /opt/stack/undercloud-live/bin/common.sh

# The commands in this script require a running, configured cloud.

if [ -f /opt/stack/undercloud-live/.setup ]; then
    exit
fi

sudo cp /root/stackrc $HOME/undercloudrc
source $HOME/undercloudrc

# Ensure keystone is up before continuing on.
# Waits for up to 2 minutes.
wait_for 12 10 sudo systemctl status keystone

# Because keystone just still isn't up yet...
sleep 20

# Make sure we have the latest $PATH set.
source /etc/profile.d/tripleo-incubator-scripts.sh

export UNDERCLOUD_IP=192.0.2.1

# Baremetal setup
# Doing this as root b/c when this script is called from systemd, the access
# to the libvirtd socket is restricted.
sudo -i /opt/stack/tripleo-incubator/scripts/create-nodes 1 2048 20 amd64 2

cat /opt/stack/boot-stack/virtual-power-key.pub >> /home/$USER/.ssh/authorized_keys

sudo touch /opt/stack/undercloud-live/.setup
