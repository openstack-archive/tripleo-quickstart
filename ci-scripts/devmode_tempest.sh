#!/bin/bash
# CI test that updates upstream images to latest delorean and runs tempest.
# Usage: tempest.sh <release> <build_system> <config> <job_type>
set -eux

RELEASE=$1
BUILD_SYS=$2
CONFIG=$3
JOB_TYPE=$4

# (trown) This is so that we ensure separate ssh sockets for
# concurrent jobs. Without this, two jobs running in parallel
# would try to use the same undercloud-stack socket.
socketdir=$(mktemp -d /tmp/sockXXXXXX)
export ANSIBLE_SSH_CONTROL_PATH=$socketdir/%%h-%%r

pushd $WORKSPACE/tripleo-quickstart

bash $WORKSPACE/tripleo-quickstart/quickstart.sh \
    --tags all \
    --config $WORKSPACE/config/general_config/$CONFIG.yml \
    --working-dir $WORKSPACE/ \
    --no-clone \
    --release master-tripleo-ci
    --extra-vars test_ping=False \
    --playbook quickstart-extras.yml \
    $VIRTHOST

bash $WORKSPACE/tripleo-quickstart/quickstart.sh \
    --tags all \
    --working-dir $WORKSPACE/ \
    --no-clone \
    --bootstrap \
    --retain-inventory \
    --requirements $WORKSPACE/tripleo-quickstart/quickstart-extras-requirements.txt \
    --playbook tempest.yml \
    --extra-vars tempest_source=rdo \
    --extra-vars tempest_format=venv \
    --playbook quickstart-extras.yml \
    $VIRTHOST

popd
