#!/bin/bash
# Used to run quickstart with ansible-role-tripleo-* repositories
# Usage: roles-deploy.sh <release> <build_system> <config> <job_type>
set -eux

# CONFIG and JOB_TYPE are not used here, but kept for
# consistency with other jobs to make JJB cleaner.
RELEASE=$1
BUILD_SYS=$2
CONFIG=$3
JOB_TYPE=$4

if [ "$JOB_TYPE" = "gate" ] || [ "$JOB_TYPE" = "periodic" ] || [ "$JOB_TYPE" = "dlrn-gate" ]; then
    LOCATION='stable'
elif [ "$JOB_TYPE" = "promote" ] || [ "$JOB_TYPE" = "dlrn-gate-testing" ]; then
    LOCATION='testing'
else
    echo "Job type must be one of gate, dlrn-gate, dlrn-gate-testing, periodic, or promote"
    exit 1
fi

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

if [ "$JOB_TYPE" = "dlrn-gate" ] || [ "$JOB_TYPE" = "dlrn-gate-testing" ]; then
    # provison the virthost and build the gated DLRN packages
    bash $WORKSPACE/tripleo-quickstart/quickstart.sh \
        --working-dir $WORKSPACE/ \
        --no-clone \
        --bootstrap \
        --extra-vars artg_compressed_gating_repo="/home/stack/gating_repo.tar.gz" \
        --requirements $WORKSPACE/tripleo-quickstart/quickstart-role-requirements.txt \
        --playbook dlrn-gate.yml \
        --tags all \
        --teardown all \
        --release $RELEASE \
        $VIRTHOST
    # skip provisioning and run the gate using the previously built RPMs
    bash $WORKSPACE/tripleo-quickstart/quickstart.sh \
        --working-dir $WORKSPACE/ \
        --no-clone \
        --retain-inventory \
        --extra-vars compressed_gating_repo="/home/stack/gating_repo.tar.gz" \
        --extra-vars undercloud_image_url="http://artifacts.ci.centos.org/artifacts/rdo/images/$RELEASE/$BUILD_SYS/$LOCATION/undercloud.qcow2" \
        --config $WORKSPACE/config/general_config/$CONFIG.yml \
        --playbook tripleo-roles.yml \
        --skip-tags provision,undercloud-post-install \
        --tags all \
        --teardown none \
        --release $RELEASE \
        $VIRTHOST
else
    # run the gate job using gated roles and the role based playbook
    bash $WORKSPACE/tripleo-quickstart/quickstart.sh \
        --working-dir $WORKSPACE/ \
        --no-clone \
        --bootstrap \
        --requirements $WORKSPACE/tripleo-quickstart/quickstart-role-requirements.txt \
        --extra-vars undercloud_image_url="http://artifacts.ci.centos.org/artifacts/rdo/images/$RELEASE/$BUILD_SYS/$LOCATION/undercloud.qcow2" \
        --config $WORKSPACE/config/general_config/$CONFIG.yml \
        --playbook tripleo-roles.yml \
        --skip-tags undercloud-post-install \
        --tags all \
        --release $RELEASE \
        $VIRTHOST
fi
