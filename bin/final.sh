 #!/bin/bash

 set -eux

 source /etc/sysconfig/undercloud-live-config
 source /etc/sysconfig/undercloudrc 

 TRIPLEO_ROOT=/home/jslagle/tripleo setup-baremetal $NODE_CPU $NODE_MEM $NODE_DISK $NODE_ARCH "$UNDERCLOUD_MACS" undercloud-leaf
