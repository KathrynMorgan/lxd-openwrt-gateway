#!/bin/bash
# Test lxd+ovs+OpenWRT Image on clean Ubuntu OS

# Define host iface to use
wan_IFACE="ens7"

# Install LXD on Xenial
#add-apt-repository ppa:ubuntu-lxc/daily -y
#apt install -t xenial-backports lxd lxd-client

# Install Packages
#apt update && apt upgrade -y

# NOTE: "ifupdown" required on bionic due to current NetPlan limitations
apt install -y openvswitch-switch ifupdown git

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
config:
  images.auto_update_interval: "0"
cluster: null
networks: []
storage_pools:
- config:
    size: 15GB
  description: ""
  name: default
  driver: btrfs
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      nictype: macvlan
      parent: openwrt-wan
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
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
lxc start gw
lxc exec gw ash
lxc list

