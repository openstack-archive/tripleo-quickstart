#!/bin/bash
# CI test that builds images for both promote and gate jobs.
# For the promote jobs it publishes the image to the testing location.
# For the gate jobs it tests them with a full deploy.
# Usage: images.sh <release> <build_system> <config> <job_type>
set -eux

RELEASE=$1
BUILD_SYS=$2
CONFIG=$3
JOB_TYPE=$4

# These are set here to make it possible to locally reproduce the promote
# image building job in the same way as the other jobs.
PUBLISH=${PUBLISH:-"false"}
delorean_current_hash=${delorean_current_hash:-"consistent"}
REL_TYPE=${LOCATION:-"testing"}

if [ "$JOB_TYPE" = "gate" ] || [ "$JOB_TYPE" = "periodic" ]; then
    PLAYBOOK='build-images-and-quickstart.yml'
    delorean_current_hash='current-passed-ci'
elif [ "$JOB_TYPE" = "promote" ]; then
    PLAYBOOK='build-images.yml'
else
    echo "Job type must be one of gate, periodic, or promote"
    exit 1
fi

# (trown) This is so that we ensure separate ssh sockets for
# concurrent jobs. Without this, two jobs running in parallel
# would try to use the same undercloud-stack socket.
socketdir=$(mktemp -d /tmp/sockXXXXXX)
export ANSIBLE_SSH_CONTROL_PATH=$socketdir/%%h-%%r

bash quickstart.sh \
    --tags all \
    --config $WORKSPACE/config/general_config/$CONFIG.yml \
    --working-dir $WORKSPACE/ \
    --playbook $PLAYBOOK \
    --extra-vars undercloud_image_url="file:///var/lib/oooq-images/undercloud.qcow2" \
    --extra-vars artib_release=$RELEASE \
    --extra-vars artib_build_system=$BUILD_SYS \
    --extra-vars artib_delorean_hash=$delorean_current_hash \
    --extra-vars publish=$PUBLISH \
    --extra-vars artib_image_stage_location="$REL_TYPE" \
    --bootstrap \
    --no-clone \
    --release ${CI_ENV:+$CI_ENV/}$RELEASE \
    $VIRTHOST
