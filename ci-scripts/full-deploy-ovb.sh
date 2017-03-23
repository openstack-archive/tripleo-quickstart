#!/bin/bash
# CI test that does a full deploy on Openstack Virtual Baremetal.
# $HW_ENV_DIR is the directory where environment-specific files are kept.
# $JOB_TYPE used are 'periodic' and 'gate'
# Usage: full-deploy-ovb.sh \
#        <release> \
#        <hw-env-dir> \
#        <network-isolation> \
#        <config> \
#        <ovb-settings-file> \
#        <ovb-creds-file>  \
#        <playbook> \
#        <job-type>

set -eux

: ${OPT_ADDITIONAL_PARAMETERS:=""}

RELEASE=$1
HW_ENV_DIR=$2
NETWORK_ISOLATION=$3
CONFIG=$4
OVB_SETTINGS_FILE=$5
OVB_CREDS_FILE=$6
PLAYBOOK=$7
JOB_TYPE=$8

socketdir=$(mktemp -d /tmp/sockXXXXXX)
export ANSIBLE_SSH_CONTROL_PATH=$socketdir/%%h-%%r

# preparation steps to run with the gated roles
if [ "$JOB_TYPE" = "gate" ]; then
    bash quickstart.sh \
        --working-dir $WORKSPACE/ \
        --no-clone \
        --bootstrap \
        --playbook gate-quickstart.yml \
        --release ${CI_ENV:+$CI_ENV/}$RELEASE${REL_TYPE:+-$REL_TYPE} \
        $OPT_ADDITIONAL_PARAMETERS \
        localhost
fi

bash quickstart.sh \
    --bootstrap \
    --working-dir $WORKSPACE/ \
    --tags all \
    --no-clone \
    --config $WORKSPACE/$HW_ENV_DIR/network_configs/$NETWORK_ISOLATION/config_files/$CONFIG \
    --extra-vars @$OVB_SETTINGS_FILE \
    --extra-vars @$OVB_CREDS_FILE \
    --extra-vars @$WORKSPACE/$HW_ENV_DIR/network_configs/$NETWORK_ISOLATION/env_settings.yml \
    --playbook $PLAYBOOK \
    --release ${CI_ENV:+$CI_ENV/}$RELEASE${REL_TYPE:+-$REL_TYPE} \
    $OPT_ADDITIONAL_PARAMETERS \
    localhost

