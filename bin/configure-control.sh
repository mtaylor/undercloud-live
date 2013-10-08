#!/bin/bash

set -eux

if [ -e /opt/stack/undercloud-live/.configure ]; then
    echo configure.sh has already run, exiting.
    exit
fi

# rabbitmq-server does not start with selinux enforcing.
# https://bugzilla.redhat.com/show_bug.cgi?id=998682
sudo setenforce 0

# this fixes a bug in python-dib-elements. not all element scripts should be
# applied with sudo.
sudo chown -R $USER.$USER $HOME/.cache

# this often reports failure, even though the service is up
sudo service rabbitmq-server restart || true

# Make sure sshd is enabled and started by default
sudo systemctl enable sshd
sudo systemctl start sshd

sudo touch /opt/stack/undercloud-live/.configure