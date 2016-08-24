#!/bin/bash
# CI test that does a full deploy for both promote and gate jobs.
# For the promote jobs it runs against the image in the testing location.
# For the gate jobs it runs against the image in the stable location.
# Usage: full-deploy.sh <release> <build_system> <config> <job_type>
set -eux

RELEASE=$1
# unused variable in script, kept for consistency
BUILD_SYS=$2
CONFIG=$3
JOB_TYPE=$4

if [ "$JOB_TYPE" = "gate" ] || [ "$JOB_TYPE" = "periodic" ]; then
    unset REL_TYPE
elif [ "$JOB_TYPE" = "promote" ]; then
    REL_TYPE="${LOCATION:-'testing'}"
else
    echo "Job type must be one of gate, periodic, or promote"
    exit 1
fi

# (trown) This is so that we ensure separate ssh sockets for
# concurrent jobs. Without this, two jobs running in parallel
# would try to use the same undercloud-stack socket.
socketdir=$(mktemp -d /tmp/sockXXXXXX)
export ANSIBLE_SSH_CONTROL_PATH=$socketdir/%%h-%%r

pushd $WORKSPACE/tripleo-quickstart
bash quickstart.sh \
    --tags all \
    --config $WORKSPACE/config/general_config/$CONFIG.yml \
    --working-dir $WORKSPACE/ \
    --no-clone \
    --release ${CI_ENV:+$CI_ENV/}$RELEASE${REL_TYPE:+-$REL_TYPE} \
    $VIRTHOST
popd
