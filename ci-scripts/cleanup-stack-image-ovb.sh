#!/bin/bash
# CI test that cleans up a deploy and image on Openstack Virtual Baremetal.
# $HW_ENV_DIR is the directory where environment-specific files are kept.
# $REQUIREMENTS_FILE is used to include any additional repositories
# Usage: cleanup-stack-image-ovb.sh \
#        <hw-env-dir> \
#        <network-isolation> \
#        <requirements-file> \
#        <ovb-creds-file>  \
#        <playbook>

set -eux

HW_ENV_DIR=$1
NETWORK_ISOLATION=$2
REQUIREMENTS_FILE=$3
OVB_CREDS_FILE=$4
PLAYBOOK=$5

# env file is named <prefix>env.yaml
# prefix is built from:
# "{{ 1000 |random }}"-"{{ lookup('env', 'USER') }}"-"{{ lookup('env', 'BUILD_NUMBER') }}"-

export PREFIX=$(ls $WORKSPACE | grep -h env.yaml | sed -n -e 's/env.yaml//p')
echo $PREFIX

#undercloud_image is named <prefix><release>-undercloud.qcow2
export RELEASE=$(cat $WORKSPACE/${PREFIX}env.yaml | grep 'undercloud_image' | rev | cut -d'-' -f 2 | rev)
echo $RELEASE

pushd $WORKSPACE/tripleo-quickstart

bash quickstart.sh \
--ansible-debug \
--bootstrap \
--working-dir $WORKSPACE/ \
--requirements quickstart-role-requirements.txt \
--requirements $WORKSPACE/$HW_ENV_DIR/network_configs/$NETWORK_ISOLATION/requirements_files/$REQUIREMENTS_FILE \
--release $RELEASE \
--extra-vars prefix=$PREFIX \
--extra-vars @$OVB_CREDS_FILE \
--playbook $PLAYBOOK \
localhost
popd
