#!/bin/bash
# CI test that cleans up a deploy and image on Openstack Virtual Baremetal.
# $HW_ENV_DIR is the directory where environment-specific files are kept.
# Usage: cleanup-stack-image-ovb.sh \
#        <hw-env-dir> \
#        <network-isolation> \
#        <ovb-creds-file>  \
#        <playbook>

set -eux

HW_ENV_DIR=$1
NETWORK_ISOLATION=$2
OVB_CREDS_FILE=$3
PLAYBOOK=$4

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
--requirements quickstart-extras-requirements.txt \
--release $RELEASE \
--extra-vars prefix=$PREFIX \
--extra-vars @$OVB_CREDS_FILE \
--playbook $PLAYBOOK \
localhost
popd
