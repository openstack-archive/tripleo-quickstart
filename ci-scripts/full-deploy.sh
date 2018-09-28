#!/bin/bash
# CI test that does a full deploy for both promote and gate jobs.
# For the promote jobs it runs against the image in the testing location.
# For the gate jobs it runs against the image in the stable location.
# Usage: full-deploy.sh <release> <build_system> <config> <job_type>
set -eux

: ${OPT_ADDITIONAL_PARAMETERS:=""}
: ${WORKSPACE:=$HOME/.quickstart}
: ${VIRTHOST:=127.0.0.1}

RELEASE=${1:-master-tripleo-ci}
# unused variable in script, kept for consistency
BUILD_SYS=${2:-delorean}
CONFIG=${3:-minimal}
JOB_TYPE=${4:-standalone}

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
    export ZUUL_CHANGES=openstack/tripleo-heat-templates:master:refs/changes/70/528770/1
    unset REL_TYPE
    if [ "$RELEASE" = "master-tripleo-ci" ]; then
        # we don't have a local mirror for the tripleo-ci images
        unset CI_ENV
    fi
elif [ "$JOB_TYPE" = "promote" ]; then
    REL_TYPE=$LOCATION
elif [ "$JOB_TYPE" = "standalone" ] || [ "$JOB_TYPE" = "standalone3" ]; then
    echo "using standalone, single node deployment"
else
    echo "Job type must be one of the following:"
    echo " * gate - for gating changes on tripleo-quickstart or -extras"
    echo " * promote - for running promotion jobs"
    echo " * periodic - for running periodic jobs"
    echo " * dlrn-gate - for gating upstream changes"
    echo " * dlrn-gate-check - for gating upstream changes"
    echo " * standalone - for standalone deployments"
    echo " * standalone3 - for standalone deployments"
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
case "$JOB_TYPE" in
    dlrn-gate*)
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
            --skip-tags provision \
            --tags all \
            --teardown none \
            --release ${CI_ENV:+$CI_ENV/}$RELEASE${REL_TYPE:+-$REL_TYPE} \
            $OPT_ADDITIONAL_PARAMETERS \
            $VIRTHOST
        ;;
    standalone)
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

        bash quickstart.sh \
            --working-dir $WORKSPACE/ \
            --no-clone \
            --retain-inventory \
            --config $WORKSPACE/config/general_config/$CONFIG.yml \
            --environment $WORKSPACE/config/environments/standalone_centos_libvirt.yml \
            --skip-tags provision \
            --tags all \
            --teardown none \
            --playbook quickstart-extras-standalone.yml \
            --release ${CI_ENV:+$CI_ENV/}$RELEASE${REL_TYPE:+-$REL_TYPE} \
            $OPT_ADDITIONAL_PARAMETERS \
            $VIRTHOST
        ;;
    standalone3)
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

        bash quickstart.sh \
            --working-dir $WORKSPACE/ \
            --no-clone \
            --retain-inventory \
            --config $WORKSPACE/config/general_config/$CONFIG.yml \
            --environment $WORKSPACE/config/environments/standalone_fedora_libvirt.yml \
            --skip-tags provision \
            --tags all \
            --teardown none \
            --playbook quickstart-extras-standalone.yml \
            --release tripleo-ci/master_fedora28 \
            $OPT_ADDITIONAL_PARAMETERS \
            $VIRTHOST
        ;;
    *)
        bash quickstart.sh \
            --bootstrap \
            --tags all \
            --config $WORKSPACE/config/general_config/$CONFIG.yml \
            --working-dir $WORKSPACE/ \
            --no-clone \
            --release ${CI_ENV:+$CI_ENV/}$RELEASE${REL_TYPE:+-$REL_TYPE} \
            $OPT_ADDITIONAL_PARAMETERS \
            $VIRTHOST
esac
