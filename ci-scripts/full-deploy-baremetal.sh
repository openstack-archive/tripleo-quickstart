#!/bin/bash
# CI test that does a full deploy on baremetal hardware.
# $HW_ENV_DIR is the directory where environment-specific files are kept.
# Usage: full-deploy-baremetal.sh \
#        <release> \
#        <hw-env-dir> \
#        <network-isolation> \
#        <config-file> \
#        <playbook>

set -eux

: ${OPT_ADDITIONAL_PARAMETERS:=""}

RELEASE=$1
HW_ENV_DIR=$2
NETWORK_ISOLATION=$3
CONFIG_FILE=$4
PLAYBOOK=$5
socketdir=$(mktemp -d /tmp/sockXXXXXX)
export ANSIBLE_SSH_CONTROL_PATH=$socketdir/%%h-%%r

bash quickstart.sh \
    --bootstrap \
    --working-dir $WORKSPACE/ \
    --tags all \
    --no-clone \
    --teardown all \
    --config $WORKSPACE/$HW_ENV_DIR/network_configs/$NETWORK_ISOLATION/config_files/$CONFIG_FILE \
    --environment $WORKSPACE/$HW_ENV_DIR/network_configs/$NETWORK_ISOLATION/env_settings.yml \
    --playbook $PLAYBOOK \
    --extra-vars undercloud_instackenv_template=$WORKSPACE/$HW_ENV_DIR/instackenv.json \
    --extra-vars network_environment_file=$WORKSPACE/$HW_ENV_DIR/network_configs/$NETWORK_ISOLATION/${NETWORK_ISOLATION}.yml \
    --extra-vars nic_configs_dir=$WORKSPACE/$HW_ENV_DIR/network_configs/$NETWORK_ISOLATION/nic_configs/ \
    --release ${CI_ENV:+$CI_ENV/}$RELEASE${REL_TYPE:+-$REL_TYPE} \
    $OPT_ADDITIONAL_PARAMETERS \
    $VIRTHOST
