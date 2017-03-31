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
VIRTHOST=localhost

if [ "$JOB_TYPE" = "gate" ] || \
   [ "$JOB_TYPE" = "periodic" ] || \
   [ "$JOB_TYPE" = "dlrn-gate" ]; then
    unset REL_TYPE
    if [ "$RELEASE" = "master-tripleo-ci" ]; then
        # we don't have a local mirror for the tripleo-ci images
        unset CI_ENV
    fi
elif [ "$JOB_TYPE" = "dlrn-gate-check" ]; then
    # setup a test patch to be built
    export ZUUL_HOST=review.openstack.org
    export ZUUL_CHANGES=openstack/tripleo-ui:master:refs/changes/25/422025/3
    unset REL_TYPE
    if [ "$RELEASE" = "master-tripleo-ci" ]; then
        # we don't have a local mirror for the tripleo-ci images
        unset CI_ENV
    fi
elif [ "$JOB_TYPE" = "promote" ]; then
    export REL_TYPE=$LOCATION
else
    echo "Job type must be one of the following:"
    echo " * gate - for gating changes on tripleo-quickstart or -extras"
    echo " * promote - for running promotion jobs"
    echo " * periodic - for running periodic jobs"
    echo " * dlrn-gate - for gating upstream changes"
    echo " * dlrn-gate-check - for gating upstream changes"
    exit 1
fi

# (trown) This is so that we ensure separate ssh sockets for
# concurrent jobs. Without this, two jobs running in parallel
# would try to use the same undercloud-stack socket.
socketdir=$(mktemp -d /tmp/sockXXXXXX)
export ANSIBLE_SSH_CONTROL_PATH=$socketdir/%%h-%%r

# preparation steps to run with the gated roles
CI_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CI_SCRIPT_DIR/include-gate-changes.sh

# we need to run differently (and twice) when gating upstream changes
if [ "$JOB_TYPE" = "dlrn-gate" ] || [ "$JOB_TYPE" = "dlrn-gate-check" ]; then
    echo "TODO: Add dlrn-gate section in upcoming review"
else
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
        $VIRTHOST
fi
