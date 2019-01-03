#!/bin/bash
# CI test that does an upgrade of a full oooq deployment.
# Use the major_upgrade flag to switch between major and minor upgrade
# Usage: upgrade.sh <release> <build_system> <config> <job_type> <delorean_hahs> <major_upgrade> <enable_pacemaker> [<target_upgrade_version>]
set -eux

RELEASE=$1
BUILD_SYS=$2
CONFIG=$3
JOB_TYPE=$4
DELOREAN_HASH=$5
MAJOR_UPGRADE=$6
PACEMAKER=$7
TARGET_VERSION=$8


if [ "$JOB_TYPE" = "gate" ] || [ "$JOB_TYPE" = "periodic" ]; then
    unset REL_TYPE
elif [ "$JOB_TYPE" = "promote" ]; then
    REL_TYPE=$LOCATION
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
    --config $WORKSPACE/config/general_config/$CONFIG.yml \
    --extra-vars upgrade_delorean_hash=$DELOREAN_HASH \
    --extra-vars major_upgrade=$MAJOR_UPGRADE \
    --extra-vars enable_pacemaker=$PACEMAKER \
    --extra-vars target_upgrade_version=$TARGET_VERSION \
    --extra-vars set_overcloud_workers=false \
    --working-dir $WORKSPACE/ \
    --no-clone \
    --bootstrap \
    --tags all \
    --teardown all \
    --playbook upgrade.yml \
    --release ${CI_ENV:+$CI_ENV/}$RELEASE${REL_TYPE:+-$REL_TYPE} \
    $VIRTHOST
