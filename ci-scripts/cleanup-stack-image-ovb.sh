#!/bin/bash
# CI test that cleans up a deploy and image on Openstack Virtual Baremetal.
# Usage: cleanup-stack-image-ovb.sh \
#        <ovb-creds-file>  \
#        <playbook>

set -eux

OVB_CREDS_FILE=$1
PLAYBOOK=$2

# env file is named env-{{ idnum }}.yaml
# idnum is built from:
# "{{ 100000 |random }}"

export IDNUM=$(ls $WORKSPACE | grep -h 'env-.*\.yaml' | sed -e 's/env-\(.*\).yaml/\1/')
echo $IDNUM

pushd $WORKSPACE/tripleo-quickstart

bash quickstart.sh \
--bootstrap \
--working-dir $WORKSPACE/ \
--extra-vars idnum=$IDNUM \
--extra-vars @$OVB_CREDS_FILE \
--playbook $PLAYBOOK \
localhost
popd
