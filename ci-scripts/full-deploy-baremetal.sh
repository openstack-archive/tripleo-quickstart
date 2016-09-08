#!/bin/bash
# CI test that does a full deploy on baremetal hardware.
# $HW_ENV_DIR is the directory where environment-specific files are kept.
# $REQUIREMENTS_FILE is used to include any additional repositories
# Usage: full-deploy-baremetal.sh \
#        <release> \
#        <hw-env-dir> \
#        <network-isolation> \
#        <requirements-file> \
#        <config-file> \
#        <playbook>

set -eux

RELEASE=$1
HW_ENV_DIR=$2
NETWORK_ISOLATION=$3
REQUIREMENTS_FILE=$4
CONFIG_FILE=$5
PLAYBOOK=$6

socketdir=$(mktemp -d /tmp/sockXXXXXX)
export ANSIBLE_SSH_CONTROL_PATH=$socketdir/%%h-%%r

pushd $WORKSPACE/tripleo-quickstart
bash quickstart.sh \
    --ansible-debug \
    --bootstrap \
    --working-dir $WORKSPACE/ \
    --tags all \
    --no-clone \
    --teardown all \
    --requirements quickstart-role-requirements.txt \
    --requirements $WORKSPACE/$HW_ENV_DIR/network_configs/$NETWORK_ISOLATION/requirements_files/$REQUIREMENTS_FILE \
    --config $WORKSPACE/$HW_ENV_DIR/network_configs/$NETWORK_ISOLATION/config_files/$CONFIG_FILE \
    --extra-vars @$WORKSPACE/$HW_ENV_DIR/network_configs/$NETWORK_ISOLATION/env_settings.yml \
    --playbook $PLAYBOOK \
    --extra-vars undercloud_instackenv_template=$WORKSPACE/$HW_ENV_DIR/instackenv.json \
    --extra-vars network_environment_file=$WORKSPACE/$HW_ENV_DIR/network_configs/$NETWORK_ISOLATION/${NETWORK_ISOLATION}.yml \
    --extra-vars nic_configs_dir=$WORKSPACE/$HW_ENV_DIR/network_configs/$NETWORK_ISOLATION/nic_configs/ \
    --release ${CI_ENV:+$CI_ENV/}$RELEASE${REL_TYPE:+-$REL_TYPE} \
    $VIRTHOST
popd
