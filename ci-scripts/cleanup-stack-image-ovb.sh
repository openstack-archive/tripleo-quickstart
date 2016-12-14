#!/bin/bash
# CI test that cleans up a deploy and image on Openstack Virtual Baremetal.
# Usage: cleanup-stack-image-ovb.sh \
#        <ovb-creds-file>  \
#        <playbook>

set -eux

OVB_CREDS_FILE=$1
PLAYBOOK=$2

# env file is named <prefix>env.yaml
# prefix is built from:
# "{{ 1000 |random }}"-"{{ lookup('env', 'USER') }}"-"{{ lookup('env', 'BUILD_NUMBER') }}"-

export PREFIX=$(ls $WORKSPACE | grep -h env.yaml | sed -n -e 's/env.yaml//p')
echo $PREFIX

#undercloud_image is named <prefix><release>-undercloud.qcow2
export RELEASE=$(cat $WORKSPACE/${PREFIX}env.yaml | grep 'undercloud_image' | grep -o -P "$USER-\d+-\K.*(?=-undercloud.qcow2)")
echo $RELEASE

pushd $WORKSPACE/tripleo-quickstart

bash quickstart.sh \
--bootstrap \
--working-dir $WORKSPACE/ \
--release $RELEASE \
--extra-vars prefix=$PREFIX \
--extra-vars @$OVB_CREDS_FILE \
--playbook $PLAYBOOK \
localhost
popd
