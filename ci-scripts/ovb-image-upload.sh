#!/bin/bash
# CI script to upload an undercloud image to Openstack Virtual Baremetal.
# $HW_ENV_DIR is the directory where environment-specific files are kept.
# $REQUIREMENTS_FILE is used to include any additional repositories
# Usage: ovb-image-upload.sh \
#        <release> \
#        <hw-env-dir> \
#        <network-isolation> \
#        <requirements-file> \
#        <ovb-creds-file>  \
#        <playbook>

set -eux

RELEASE=$1
HW_ENV_DIR=$2
NETWORK_ISOLATION=$3
REQUIREMENTS_FILE=$4
OVB_CREDS_FILE=$5
PLAYBOOK=$6

pushd $WORKSPACE/tripleo-quickstart

bash quickstart.sh \
--ansible-debug \
--bootstrap \
--working-dir $WORKSPACE/ \
--requirements quickstart-extras-requirements.txt \
--requirements $WORKSPACE/$HW_ENV_DIR/network_configs/$NETWORK_ISOLATION/requirements_files/$REQUIREMENTS_FILE \
--release $RELEASE \
--extra-vars @$OVB_CREDS_FILE \
--extra-vars get_latest_image='upload' \
--playbook $PLAYBOOK \
localhost
popd
