#!/bin/bash
# CI script to upload an undercloud image to Openstack Virtual Baremetal.
# $HW_ENV_DIR is the directory where environment-specific files are kept.
# Usage: ovb-image-upload.sh \
#        <release> \
#        <hw-env-dir> \
#        <network-isolation> \
#        <ovb-creds-file>  \
#        <playbook>

set -eux

RELEASE=$1
HW_ENV_DIR=$2
NETWORK_ISOLATION=$3
OVB_CREDS_FILE=$4
PLAYBOOK=$5

pushd $WORKSPACE/tripleo-quickstart

bash quickstart.sh \
--ansible-debug \
--bootstrap \
--working-dir $WORKSPACE/ \
--release $RELEASE \
--extra-vars @$OVB_CREDS_FILE \
--extra-vars get_latest_image='upload' \
--playbook $PLAYBOOK \
localhost
popd
