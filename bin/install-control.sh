#!/bin/bash

set -eux

if [ -f /opt/stack/undercloud-live/.install ]; then
    echo install.sh has already run, exiting.
    exit
fi

# Make sure pip is installed
sudo yum install -y python-pip

# busybox is a requirement of ramdisk-image-create from diskimage-builder
sudo yum install -y busybox

# Migrate over to the latest setuptools
sudo pip install -U distribute
sudo pip install -U setuptools

# For some reason, pbr is not getting installed correctly.
# It is listed as setup_requires for diskimage-builder, and 
# pip thinks it's installed from then on out, even though it is not.
sudo pip install pbr

# qemu-img is still needed to convert disks when diskimage-builder is used
sudo yum install -y python-lxml qemu-img git python-pip openssl-devel python-devel gcc audit python-virtualenv openvswitch python-yaml iptables-services

sudo mkdir -m 777 -p /opt/stack
pushd /opt/stack

git clone https://github.com/agroup/python-dib-elements.git
git clone https://github.com/agroup/undercloud-live.git
pushd undercloud-live
git checkout 2-node
popd

git clone https://github.com/openstack/tripleo-incubator.git

git clone https://github.com/openstack/diskimage-builder.git
git clone https://github.com/openstack/tripleo-image-elements.git
git clone https://github.com/openstack/tripleo-heat-templates.git

sudo pip install -e python-dib-elements
sudo pip install -e diskimage-builder

# Add scripts directory from tripleo-incubator and diskimage-builder to the
# path.
# These scripts can't just be symlinked into a bin directory because they do
# directory manipulation that assumes they're in a known location.
if [ ! -e /etc/profile.d/tripleo-incubator-scripts.sh ]; then
    sudo bash -c "echo export PATH='\$PATH':/opt/stack/tripleo-incubator/scripts/ >> /etc/profile.d/tripleo-incubator-scripts.sh"
    sudo bash -c "echo export PATH=/opt/stack/diskimage-builder/bin/:'\$PATH' >> /etc/profile.d/tripleo-incubator-scripts.sh"
fi

# This blacklists the script that removes grub2.  Obviously, we don't want to
# do that in this scenario.
dib-elements -p diskimage-builder/elements/ tripleo-image-elements/elements/ \
    -e fedora \
    -k extra-data pre-install \
    -b 15-fedora-remove-grub \
    -x neutron-openvswitch-agent \
    -i
dib-elements -p diskimage-builder/elements/ tripleo-image-elements/elements/ \
    -e source-repositories boot-stack \
    -k extra-data \
    -x neutron-openvswitch-agent \
    -i
# rabbitmq-server does not start with selinux enforcing.
# https://bugzilla.redhat.com/show_bug.cgi?id=998682
dib-elements -p diskimage-builder/elements/ tripleo-image-elements/elements/ \
                undercloud-live/elements \
    -e boot-stack \
       stackuser heat-cfntools \
       undercloud-control-config undercloud-environment \
       selinux-permissive \
    -k install \
    -x neutron-openvswitch-agent \
    -i

popd

# sudo run from nova rootwrap complains about no tty
sudo sed -i "s/Defaults    requiretty/# Defaults    requiretty/" /etc/sudoers

# Overcloud heat template
sudo make -C /opt/stack/tripleo-heat-templates overcloud.yaml

# Need to get a patch upstream for this, but for now, just fix it locally
# Run os-config-applier earlier in the os-refresh-config configure.d phase
sudo mv /opt/stack/os-config-refresh/configure.d/50-os-config-applier \
        /opt/stack/os-config-refresh/configure.d/40-os-config-applier

touch /opt/stack/undercloud-live/.install 