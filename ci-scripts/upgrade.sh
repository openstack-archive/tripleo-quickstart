#!/bin/bash
# CI test that does an upgrade of a full oooq deployment.
# Use the major_upgrade flag to switch between major and minor upgrade
# Usage: upgrade.sh <release> <build_system> <config> <job_type> <delorean_hahs> <major_upgrade> <enable_pacemaker>
set -eux

RELEASE=$1
BUILD_SYS=$2
CONFIG=$3
JOB_TYPE=$4
DELOREAN_HASH=$5
MAJOR_UPGRADE=$6
PACEMAKER=$7

SKIP_TAGS="undercloud-post-install"

if [ "$JOB_TYPE" = "gate" ] || [ "$JOB_TYPE" = "periodic" ]; then
    LOCATION='stable'
elif [ "$JOB_TYPE" = "promote" ]; then
    LOCATION='testing'
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
    -e undercloud_image_url="http://artifacts.ci.centos.org/artifacts/rdo/images/$RELEASE/$BUILD_SYS/$LOCATION/undercloud.qcow2" \
    --config $WORKSPACE/config/general_config/$CONFIG.yml \
    --extra-vars upgrade_delorean_hash=$DELOREAN_HASH \
    --extra-vars major_upgrade=$MAJOR_UPGRADE \
    --extra-vars enable_pacemaker=$PACEMAKER \
    --working-dir $WORKSPACE/ \
    --skip-tags $SKIP_TAGS \
    --no-clone \
    --bootstrap \
    --tags all \
    --teardown all \
    --requirements $WORKSPACE/tripleo-quickstart/quickstart-role-requirements.txt \
    --playbook upgrade.yml \
    --release $RELEASE \
    $VIRTHOST
popd
