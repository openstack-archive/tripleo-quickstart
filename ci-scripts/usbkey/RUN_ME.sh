#!/bin/bash
set -e

######################################################################
# This script is part of the ooo-quickstart usbkey. It's designed
# to execute the quickstart from a usbkey on a test machine directly.
#
######################################################################
#Set ansible environmental variables
source ansible_env

#launch quickstart using the local image against the localhost
USB_DIR=$PWD
pushd tripleo-quickstart
export COMMAND="bash quickstart.sh \
                --no-clone \
                --requirements ci-scripts/usbkey/usb_requirements.txt \
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

popd
