#!/bin/bash
# CI test that does a full deploy on Openstack Virtual Baremetal.
# $HW_ENV_DIR is the directory where environment-specific files are kept.
# $REQUIREMENTS_FILE is used to include any additional repositories
# Usage: full-deploy-ovb.sh \
#        <release> \
#        <hw-env-dir> \
#        <network-isolation> \
#        <requirements-file> \
#        <config-file> \
#        <ovb-settings-file> \
#        <ovb-creds-file>  \
#        <playbook>

set -eux

RELEASE=$1
HW_ENV_DIR=$2
NETWORK_ISOLATION=$3
REQUIREMENTS_FILE=$4
CONFIG_FILE=$5
OVB_SETTINGS_FILE=$6
OVB_CREDS_FILE=$7
PLAYBOOK=$8

socketdir=$(mktemp -d /tmp/sockXXXXXX)
export ANSIBLE_SSH_CONTROL_PATH=$socketdir/%%h-%%r

pushd $WORKSPACE/tripleo-quickstart
bash quickstart.sh \
    --ansible-debug \
    --bootstrap \
    --working-dir $WORKSPACE/ \
    --tags all \
    --no-clone \
    --requirements quickstart-role-requirements.txt \
    --requirements $WORKSPACE/$HW_ENV_DIR/network_configs/$NETWORK_ISOLATION/requirements_files/$REQUIREMENTS_FILE \
    --config $WORKSPACE/$HW_ENV_DIR/network_configs/$NETWORK_ISOLATION/config_files/$CONFIG_FILE \
    --extra-vars @$OVB_SETTINGS_FILE \
    --extra-vars @$OVB_CREDS_FILE \
    --extra-vars @$WORKSPACE/$HW_ENV_DIR/network_configs/$NETWORK_ISOLATION/env_settings.yml \
    --playbook $PLAYBOOK \
    --release ${CI_ENV:+$CI_ENV/}$RELEASE${REL_TYPE:+-$REL_TYPE} \
    localhost
popd
