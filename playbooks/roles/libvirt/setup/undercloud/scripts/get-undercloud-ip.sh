#!/bin/sh
set -eu

PATH=$PATH:/usr/sbin:/sbin

VMNAME=$1

vm=$(sudo virsh list --all | grep $VMNAME | awk '{ print $2 }')

mac=$(sudo virsh dumpxml $vm | grep "mac address" | head -1 | awk -F "'" '{ print $2 }')

ip=$(ip neigh | grep $mac | awk '{print $1;}')

echo -en $ip