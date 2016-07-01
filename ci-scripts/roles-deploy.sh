#!/bin/bash
# Used to gate ansible-role-tripleo-* repositories
# Usage: gate-roles.sh <release> <build_system> <config> <job_type>
set -eux

# CONFIG and JOB_TYPE are not used here, but kept for
# consistency with other jobs to make JJB cleaner.
RELEASE=$1
BUILD_SYS=$2
CONFIG=$3
JOB_TYPE=$4

SKIP_TAGS="undercloud-post-install"

if [ "$JOB_TYPE" = "gate" ] || [ "$JOB_TYPE" = "periodic" ]; then
    LOCATION='stable'
elif [ "$JOB_TYPE" = "promote" ]; then
    LOCATION='testing'
else
    echo "Job type must be one of gate, periodic, or promote"
    exit 1
fi

export SSH_CONFIG=$WORKSPACE/ssh.config.ansible
export ANSIBLE_SSH_ARGS="-F ${SSH_CONFIG}"
# (trown) This is so that we ensure separate ssh sockets for
# concurrent jobs. Without this, two jobs running in parallel
# would try to use the same undercloud-stack socket.
socketdir=$(mktemp -d /tmp/sockXXXXXX)
export ANSIBLE_SSH_CONTROL_PATH=$socketdir/%%h-%%r

if [ "$JOB_TYPE" = "gate" ]; then
    # set up the gated repos and modify the requirements file to use them
    bash $WORKSPACE/tripleo-quickstart/quickstart.sh \
        --working-dir $WORKSPACE/ \
        --no-clone \
        --bootstrap \
        --requirements $WORKSPACE/tripleo-quickstart/quickstart-role-requirements.txt \
        --playbook gate-roles.yml \
        --release $RELEASE \
        $VIRTHOST

    # once more to let the gating role be gated as well
    bash $WORKSPACE/tripleo-quickstart/quickstart.sh \
        --working-dir $WORKSPACE/ \
        --no-clone \
        --bootstrap \
        --requirements $WORKSPACE/tripleo-quickstart/quickstart-role-requirements.txt \
        --playbook gate-roles.yml \
        --release $RELEASE \
        $VIRTHOST
fi

# run the gate job using gated roles and the role based playbook
bash $WORKSPACE/tripleo-quickstart/quickstart.sh \
    --working-dir $WORKSPACE/ \
    --no-clone \
    --bootstrap \
    --requirements $WORKSPACE/tripleo-quickstart/quickstart-role-requirements.txt \
    -e undercloud_image_url="http://artifacts.ci.centos.org/artifacts/rdo/images/$RELEASE/$BUILD_SYS/$LOCATION/undercloud.qcow2" \
    --config $WORKSPACE/config/general_config/$CONFIG.yml \
    --playbook tripleo-roles.yml \
    --skip-tags $SKIP_TAGS \
    --tags all \
    --release $RELEASE \
    $VIRTHOST
