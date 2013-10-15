#!/bin/bash

set -eux

if [ -e /opt/stack/undercloud-live/.configure-control ]; then
    echo configure-control.sh has already run, exiting.
    exit
fi

# rabbitmq-server does not start with selinux enforcing.
# https://bugzilla.redhat.com/show_bug.cgi?id=998682
sudo setenforce 0

# this fixes a bug in python-dib-elements. not all element scripts should be
# applied with sudo.
sudo chown -R $USER.$USER $HOME/.cache

# ssh configuration
if [ ! -f ~/.ssh/id_rsa.pub ]; then
    ssh-keygen -b 1024 -N '' -f ~/.ssh/id_rsa
fi

if [ ! -f ~/.ssh/authorized_keys ]; then
    touch ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
fi

# this often reports failure, even though the service is up
sudo service rabbitmq-server restart || true

sudo touch /opt/stack/undercloud-live/.configure-control
