#!/bin/sh

# This script will attempt to get the ip address of the a given libvirt guest.

set -eu

PATH=$PATH:/usr/sbin:/sbin

VMNAME=$1

# Get the MAC address of the first interface by looking for looking for the
# `<mac address...` line.  Yes, we're parsing XML with awk.  It's probably
# safe (because the XML is coming from libvirt, so we can be reasonably
# confident that the formatting will remain the same).
mac=$(virsh dumpxml $VMNAME | awk -F "'" '/mac address/ { print $2; exit }')

# Look up the MAC address in the ARP table
# Fallback to dhcp leases info
ip=$(ip neigh | grep $mac | awk '{print $1;}')
if [ -z "$ip" ]; then
    ip=$(virsh net-dhcp-leases default --mac $mac 2>/dev/null | awk 'BEGIN {FS="ipv[46]|/"} {gsub(/ /,""); if ($2) print $2}')
fi

if [ -z "$ip" ]; then
    echo "undercloud ip is not available" >&2
    exit 1
fi

echo $ip
