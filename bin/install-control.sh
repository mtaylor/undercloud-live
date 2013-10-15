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

sudo yum install -y which

# iptables is used instead of firewalld
sudo yum install -y iptables-services

# The packaged version of pbr that gets installed is
# python-pbr-0.5.19-2.fc19.noarch
# However, the unpackaged os-*-config expect pbr>=0.5.21, so we need to still
# use pip to update pbr for now.
sudo pip install -U pbr

# This directory is still required because not all the elements in
# tripleo-puppet-elements has been updated to use packages, specifically
# os-*-config still use git clones and expect this directory to be created.
sudo mkdir -m 777 -p /opt/stack
pushd /opt/stack

git clone https://github.com/agroup/python-dib-elements.git
git clone https://github.com/agroup/undercloud-live.git
pushd undercloud-live
git checkout slagle/package
git pull
popd

git clone https://github.com/openstack/tripleo-incubator.git
pushd tripleo-incubator
# Oct 8 commit 'Switch from ">/dev/stderr" to ">&2"'
# For the next ones let's use cherry-pick.
# NOTE(lucasagomes): cherry-pick will require the git
# global config to be set
git reset --hard 8031466c1688e686d121de9a59fd4b59096b9115

# Fix path to keystone-manage as called from init-keystone.
# The full path in init-keystone is not the correct one when we install from packages.
# Need to figure out the right patch to get this upstream.
sed -i "s#/opt/stack/venvs/keystone/bin/keystone-manage#keystone-manage#" scripts/init-keystone
popd

git clone https://github.com/openstack/diskimage-builder.git
pushd diskimage-builder
git checkout 9211a7fecbadc13e8254085133df1e3b53f150d8
popd

git clone https://github.com/agroup/tripleo-puppet-elements

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

# sudo run from nova rootwrap complains about no tty
sudo sed -i "s/Defaults    requiretty/# Defaults    requiretty/" /etc/sudoers
# need to be able to pass in a modified $PATH for sudo for dib-elements to work
sudo sed -i "s/Defaults    secure_path/# Defaults    secure_path/" /etc/sudoers

# need to move this somewhere in heat package or puppet module
sudo mkdir -p /var/log/heat
sudo touch /var/log/heat/engine.log

# This blacklists the script that removes grub2.  Obviously, we don't want to
# do that in this scenario.
dib-elements -p diskimage-builder/elements/ tripleo-puppet-elements/elements/ \
    -e fedora openstack-m-repo \
    -k extra-data pre-install \
    -b 15-fedora-remove-grub \
    -x neutron-openvswitch-agent yum \
    -i
dib-elements -p diskimage-builder/elements/ tripleo-puppet-elements/elements/ \
    -e source-repositories boot-stack \
    -k extra-data \
    -x neutron-openvswitch-agent yum \
    -i
# rabbitmq-server does not start with selinux enforcing.
# https://bugzilla.redhat.com/show_bug.cgi?id=998682
dib-elements -p diskimage-builder/elements/ tripleo-puppet-elements/elements/ \
                undercloud-live/elements \
    -e boot-stack \
       stackuser heat-cfntools \
       undercloud-control-config undercloud-environment \
       selinux-permissive \
    -k install \
    -x neutron-openvswitch-agent yum \
    -i

popd

# need to move this somewhere in heat package or puppet module
sudo chown heat /var/log/heat/engine.log

# Overcloud heat template
sudo make -C /opt/stack/tripleo-heat-templates overcloud.yaml

# Need to get a patch upstream for this, but for now, just fix it locally
# Run os-config-applier earlier in the os-refresh-config configure.d phase
sudo mv /opt/stack/os-config-refresh/configure.d/50-os-config-applier \
        /opt/stack/os-config-refresh/configure.d/40-os-config-applier

touch /opt/stack/undercloud-live/.install 
