#!/bin/bash
# Used to run quickstart with ansible-role-tripleo-* repositories
# Usage: roles-deploy.sh <release> <build_system> <config> <job_type>
set -eux

# CONFIG and JOB_TYPE are not used here, but kept for
# consistency with other jobs to make JJB cleaner.
RELEASE=$1
# unused variable in script, kept for consistency
BUILD_SYS=$2
CONFIG=$3
JOB_TYPE=$4

if [ "$JOB_TYPE" = "gate" ] || [ "$JOB_TYPE" = "periodic" ] || [ "$JOB_TYPE" = "dlrn-gate" ]; then
    unset REL_TYPE
elif [ "$JOB_TYPE" = "promote" ]; then
    REL_TYPE=$LOCATION
elif [ "$JOB_TYPE" = "dlrn-gate-testing" ]; then
    REL_TYPE="current-tripleo"
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
        --requirements $WORKSPACE/tripleo-quickstart/quickstart-extras-requirements.txt \
        --playbook gate-roles.yml \
        --release ${CI_ENV:+$CI_ENV/}$RELEASE${REL_TYPE:+-$REL_TYPE} \
        $VIRTHOST

    # once more to let the gating role be gated as well
    bash $WORKSPACE/tripleo-quickstart/quickstart.sh \
        --working-dir $WORKSPACE/ \
        --no-clone \
        --bootstrap \
        --requirements $WORKSPACE/tripleo-quickstart/quickstart-extras-requirements.txt \
        --playbook gate-roles.yml \
        --release ${CI_ENV:+$CI_ENV/}$RELEASE${REL_TYPE:+-$REL_TYPE} \
        $VIRTHOST
fi

if [ "$JOB_TYPE" = "dlrn-gate" ] || [ "$JOB_TYPE" = "dlrn-gate-testing" ]; then
    # provison the virthost and build the gated DLRN packages
    bash $WORKSPACE/tripleo-quickstart/quickstart.sh \
        --working-dir $WORKSPACE/ \
        --no-clone \
        --bootstrap \
        --extra-vars artg_compressed_gating_repo="/home/stack/gating_repo.tar.gz" \
        --requirements $WORKSPACE/tripleo-quickstart/quickstart-extras-requirements.txt \
        --playbook dlrn-gate.yml \
        --tags all \
        --teardown all \
        --release ${CI_ENV:+$CI_ENV/}$RELEASE${REL_TYPE:+-$REL_TYPE} \
        $VIRTHOST
    # skip provisioning and run the gate using the previously built RPMs
    bash $WORKSPACE/tripleo-quickstart/quickstart.sh \
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
        $VIRTHOST
else
    # run the gate job using gated roles and the role based playbook
    bash $WORKSPACE/tripleo-quickstart/quickstart.sh \
        --working-dir $WORKSPACE/ \
        --no-clone \
        --bootstrap \
        --requirements $WORKSPACE/tripleo-quickstart/quickstart-extras-requirements.txt \
        --config $WORKSPACE/config/general_config/$CONFIG.yml \
        --playbook quickstart-extras.yml \
        --tags all \
        --release ${CI_ENV:+$CI_ENV/}$RELEASE${REL_TYPE:+-$REL_TYPE} \
        $VIRTHOST
fi
