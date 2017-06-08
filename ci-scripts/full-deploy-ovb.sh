#!/bin/bash
# CI test that does a full deploy on Openstack Virtual Baremetal.
# $HW_ENV_DIR is the directory where environment-specific files are kept.
# $JOB_TYPE used are 'periodic' and 'gate'
# Usage: full-deploy-ovb.sh \
#        <release> \
#        <config> \
#        <job-type> \
#        <environment-file> \
#        <custom-requirements-install> \
#        <delete-all-stacks>

set -eux

: ${OPT_ADDITIONAL_PARAMETERS:=""}

RELEASE=$1
CONFIG=$2
JOB_TYPE=$3
ENVIRONMENT=$4
CUSTOM_REQUIREMENTS_INSTALL=$5
DELETE_ALL_STACKS=$6
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
    export ZUUL_CHANGES=openstack/tripleo-ui:master:refs/changes/25/422025/4
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

# Preparation steps to run with the gated roles
CI_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $CI_SCRIPT_DIR/include-gate-changes.sh

# Add custom repository
if [[ $CUSTOM_REQUIREMENTS_INSTALL != "none" ]] && [[ ! $(grep "$CUSTOM_REQUIREMENTS_INSTALL" quickstart-extras-requirements.txt) ]]; then
    echo "$CUSTOM_REQUIREMENTS_INSTALL" >> $CI_SCRIPT_DIR/../quickstart-extras-requirements.txt
fi

# FIXME (rlandy) - We are not able to use the topology files
# in config/nodes/ for OVB due to the definition of the
# overcloud nodes. As a workaround, pass the $CONFIG file,
# which also contains the overcloud nodes settings, to $OPT_NODES
export OPT_NODES=${OPT_NODES:="$WORKSPACE/config/general_config/${CONFIG}.yml"}

# We need to run differently when gating upstream changes
if [ "$JOB_TYPE" = "dlrn-gate" ] || [ "$JOB_TYPE" = "dlrn-gate-check" ]; then
        bash quickstart.sh \
        --bootstrap \
        --working-dir $WORKSPACE/ \
        --tags all \
        --no-clone \
        --extra-vars build_test_packages="true" \
        --extra-vars ib_repo_image_inject="true" \
        --config $WORKSPACE/config/general_config/${CONFIG}.yml \
        --extra-vars @$WORKSPACE/config/environments/${ENVIRONMENT}.yml \
        --extra-vars cleanup_stacks_keypairs=$DELETE_ALL_STACKS \
        --playbook baremetal-full-deploy.yml \
        --release $RELEASE \
        $OPT_ADDITIONAL_PARAMETERS \
        $VIRTHOST
else
    bash quickstart.sh \
        --bootstrap \
        --working-dir $WORKSPACE/ \
        --tags all \
        --no-clone \
        --config $WORKSPACE/config/general_config/${CONFIG}.yml \
        --extra-vars @$WORKSPACE/config/environments/${ENVIRONMENT}.yml \
        --extra-vars cleanup_stacks_keypairs=$DELETE_ALL_STACKS \
        --playbook baremetal-full-deploy.yml \
        --release $RELEASE \
        $OPT_ADDITIONAL_PARAMETERS \
        $VIRTHOST
fi
