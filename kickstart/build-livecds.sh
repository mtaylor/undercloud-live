#!/bin/bash

sudo livecd-creator \
    --debug \
    --verbose \
    --title "Fedora Undercloud Control" \
    --fslabel=Fedora-Undercloud-Control \
    --cache=/var/cache/yum \
    --releasever=19 \
    -t /tmp/ \
    --config fedora-undercloud-control-livecd.ks 

sudo livecd-creator \
    --debug \
    --verbose \
    --title "Fedora Undercloud Leaf" \
    --fslabel=Fedora-Undercloud-Leaf \
    --cache=/var/cache/yum \
    --releasever=19 \
    -t /tmp/ \
    --config fedora-undercloud-leaf-livecd.ks 
