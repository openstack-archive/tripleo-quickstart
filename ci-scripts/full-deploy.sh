#!/bin/bash
# CI test that does a full deploy for both promote and gate jobs.
# For the promote jobs it runs against the image in the testing location.
# For the gate jobs it runs against the image in the stable location.
# Usage: full-deploy.sh <release> <build_system> <config> <job_type>
set -eux

: ${OPT_ADDITIONAL_PARAMETERS:=""}

RELEASE=$1
# unused variable in script, kept for consistency
BUILD_SYS=$2
CONFIG=$3
JOB_TYPE=$4

if [ "$JOB_TYPE" = "gate" ] || \
   [ "$JOB_TYPE" = "periodic" ] || \
   [ "$JOB_TYPE" = "dlrn-gate" ]; then
    unset REL_TYPE
    if [ "$RELEASE" = "master-tripleo-ci" ]; then
        # we don't have a local mirror for the tripleo-ci images
        unset CI_ENV
    fi
elif [ "$JOB_TYPE" = "promote" ]; then
    REL_TYPE=$LOCATION
else
    echo "Job type must be one of the following:"
    echo " * gate - for gating changes on tripleo-quickstart or -extras"
    echo " * promote - for running promotion jobs"
    echo " * periodic - for running periodic jobs"
    echo " * dlrn-gate - for gating upstream changes"
    exit 1
fi

# (trown) This is so that we ensure separate ssh sockets for
# concurrent jobs. Without this, two jobs running in parallel
# would try to use the same undercloud-stack socket.
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
        $VIRTHOST
fi

# we need to run differently (and twice) when gating upstream changes
if [ "$JOB_TYPE" = "dlrn-gate" ]; then
    # provison the virthost and build the gated DLRN packages
    bash quickstart.sh \
        --working-dir $WORKSPACE/ \
        --no-clone \
        --bootstrap \
        --extra-vars artg_compressed_gating_repo="/home/stack/gating_repo.tar.gz" \
        --playbook build-test-packages.yml \
        --tags all \
        --teardown all \
        --release ${CI_ENV:+$CI_ENV/}$RELEASE${REL_TYPE:+-$REL_TYPE} \
        $OPT_ADDITIONAL_PARAMETERS \
        $VIRTHOST
    # skip provisioning and run the gate using the previously built RPMs
    bash quickstart.sh \
        --working-dir $WORKSPACE/ \
        --no-clone \
        --retain-inventory \
        --extra-vars compressed_gating_repo="/home/stack/gating_repo.tar.gz" \
        --config $WORKSPACE/config/general_config/$CONFIG.yml \
        --playbook quickstart-extras.yml \
        --skip-tags provision \
        --tags all \
        --teardown none \
        --release ${CI_ENV:+$CI_ENV/}$RELEASE${REL_TYPE:+-$REL_TYPE} \
        $OPT_ADDITIONAL_PARAMETERS \
        $VIRTHOST
else
    bash quickstart.sh \
        --tags all \
        --config $WORKSPACE/config/general_config/$CONFIG.yml \
        --working-dir $WORKSPACE/ \
        --no-clone \
        --release ${CI_ENV:+$CI_ENV/}$RELEASE${REL_TYPE:+-$REL_TYPE} \
        --bootstrap \
        --playbook quickstart-extras.yml \
        $OPT_ADDITIONAL_PARAMETERS \
        $VIRTHOST
fi
