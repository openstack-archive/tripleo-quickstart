#!/bin/sh
set -eu

PATH=$PATH:/usr/sbin:/sbin

VMNAME=$1
mac=$(virsh dumpxml $VMNAME | awk -F "'" '/mac address/ { print $2; exit }')
ip=$(ip neigh | grep $mac | awk '{print $1;}')

if [ -z "$ip" ]; then
    echo "undercloud ip is not available" >&2
    exit 1
fi

echo $ip
