# OpenWRT LXD Image (Unofficial) 

###### To Use:

  1. `lxc remote add ccio https://ccio.containercraft.io:8443 --public --accept-certificate`
  2. `lxc image list ccio:`
  3. `lxc init ccio:openwrt gateway`
  4. `lxc list`
  5. `lxc config show gateway`
  6. `lxc config device add gateway ens9 nic nictype=physical parent=ens9 name=ens9`
  7. `lxc start gateway`
  8. `lxc exec gateway ash`

lxd-openwrt
===========

Scripts for building LXD images from OpenWrt rootfs tarballs. The OpenWrt SDK is used to build a patched procd package.

Requirements
------------
It's recommended you use Debian or Ubuntu on the build system. The following additional packages are required on Ubuntu 18.04:

* build-essential
* subversion
* fakeroot

Configuration
-------------
Refer to the top of build.sh.
