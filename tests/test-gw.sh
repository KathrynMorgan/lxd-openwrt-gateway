#!/bin/bash
# Test lxd+ovs+OpenWRT Image on clean Ubuntu OS

# Define host iface to use
wan_IFACE="eth0"

# Add ppa on trusty/xenial
#add-apt-repository ppa:ubuntu-lxc/stable -y

# Install Packages
apt update -y && apt upgrade -y

# NOTE: "ifupdown" required on bionic due to current NetPlan limitations
apt install -y openvswitch-switch lxd ifupdown git

# Start & Enable OVS
systemctl start openvswitch
systemctl enable openvswitch

# Add "WAN" & "LAN" bridge
ovs-vsctl add-br openwrt-wan
ovs-vsctl add-br openwrt-lan

# Add a "no-ip" interface to the openwrt-bridge as "wan" interface
ovs-vsctl add-port openwrt-wan ${wan_IFACE}

# Configure interfaces
ip link set openwrt-wan up
ip link set openwrt-lan up
ip link set ${wan_IFACE} up

# Init LXD
cat <<EOF | lxd init --preseed
architecture: x86_64
config:
  security.privileged: "true"
  volatile.apply_template: create
  volatile.base_image: 23a9983c470b88c43acfd3b70244bce21a28cd869774b78bcca5a61fb7a772d3
  volatile.eth0.hwaddr: 00:16:3e:2c:ea:f1
  volatile.eth1.hwaddr: 00:16:3e:9c:97:2b
  volatile.idmap.base: "0"
  volatile.idmap.next: '[]'
  volatile.last_state.idmap: '[]'
devices:
  eth0:
    name: eth0
    nictype: bridged
    parent: openwrt-lan
    type: nic
  eth1:
    name: eth1
    nictype: bridged
    parent: openwrt-wan
    type: nic
ephemeral: false
profiles:
- default
stateful: false
description: ""
EOF

# Abort if lxd init command exits with non 0 exit code
[[ $? == "0" ]] | exit 1

# Add CCIO Remote Image Repository
lxc remote add \
    ccio https://ccio.containercraft.io:8443 \
    --public --accept-certificate

# Create OpenWRT Gateway Container as priviliged
lxc init ccio:openwrt gw -c security.privileged=true

# Add Interfaces to the "gw" container
# WAN: eth1
# LAN: eth0
lxc network attach openwrt-lan gw eth0 eth0
lxc network attach openwrt-wan gw eth1 eth1

# Add network interfaces to gateway container
lxc list
lxc exec gw ash

