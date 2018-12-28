#!/bin/bash
# CI test that does a full deploy, scales a compute node, and validates
# the overcloud for both promote and gate jobs
# Usage: full-deploy-with-scale.sh <release> <build_system> <config> <job_type>
set -eux

RELEASE=$1
# unused variable in script, kept for consistency
BUILD_SYS=$2
CONFIG=$3
JOB_TYPE=$4

# CI_ENV is set on the slave running the jobs
# REL_TYPE can be specific release type like 'testing'

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

# run scale phase 1 against the gate job: Scale new compute node -> Delete original compute node
bash quickstart.sh \
    --working-dir $WORKSPACE/ \
    --bootstrap \
    --no-clone \
    -e deploy_timeout=75 \
    --config $WORKSPACE/config/general_config/$CONFIG.yml \
    --tags all \
    --release ${CI_ENV:+$CI_ENV/}$RELEASE${REL_TYPE:+-$REL_TYPE} \
    --playbook scale_nodes.yml \
    $VIRTHOST

# run scale phase 2 against the gate job: Re-inventory overcloud -> Validate
# Note(hrybacki): The reason we need seperate playbook execution: During scale we create
#     one /additional/ compute node and then delete the /original/ compute node.
#     The deleted node is still in memory and subsequently will cause issues
#     while re-inventorying and validating the overcloud
bash quickstart.sh \
    --working-dir $WORKSPACE/ \
    --retain-inventory \
    --config $WORKSPACE/config/general_config/$CONFIG.yml \
    --tags all \
    --release ${CI_ENV:+$CI_ENV/}$RELEASE${REL_TYPE:+-$REL_TYPE} \
    --playbook scale_nodes_verify.yml \
    $VIRTHOST
