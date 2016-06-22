#!/bin/bash
set -e

######################################################################
# This script is part of the ooo-quickstart usbkey. It's designed
# to execute the quickstart from a usbkey on a test machine directly.
#
######################################################################

if [ -f /etc/redhat-release ]; then
    if grep -q  -i "Red Hat\|CentOS" /etc/redhat-release; then
        true;
    else
        echo "Red Hat Enterprise Linux and CentOS are currently supported"
        echo "We are working to add support for Fedora."
        exit 1
    fi
else
    echo "Sorry your linux distribution is not supported at this time"
    exit 1
fi

SCRIPT=$( readlink -f "${BASH_SOURCE[0]}" )
USB_DIR=$( dirname $SCRIPT )

#Set ansible environmental variables
source $USB_DIR/ansible_env

#launch quickstart using the local image against the localhost
pushd $USB_DIR/tripleo-quickstart
export COMMAND="bash quickstart.sh \
                --playbook quickstart-usb.yml \
                --extra-vars image_cache_dir=$HOME \
                --extra-vars undercloud_image_url=file://$USB_DIR/undercloud.qcow2 \
                localhost"

#check if the current user is root
if [[ $USER == root ]]; then
    echo "Use a non-root user with sudo permissions instead of root, exiting"
    exit
fi

echo "==================================================================="
echo "Installing Dependencies"
sudo bash quickstart.sh --install-deps

echo "==================================================================="
echo "Running tripelo-quickstart in 15 seconds w/ the following command"
echo ""
echo "See https://github.com/openstack/tripleo-quickstart for the latest"
echo "documenation and source code"
echo "==================================================================="

echo ""
echo $COMMAND

sleep 15
$COMMAND

echo ""
cat <<EOF
##################################
Note to ooo-usbkey users
##################################

Access the undercloud by:

    ssh -F $HOME/.quickstart/ssh.config.local.ansible undercloud

Note: Using quickstart directly on the localhost requires a separate ssh config file.
Proceed with the above instructions.

##################################
Note to ooo-usbkey users
##################################
EOF


popd
