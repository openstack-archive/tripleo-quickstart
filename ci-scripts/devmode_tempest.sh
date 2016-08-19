#!/bin/bash
# CI test that updates upstream images to latest delorean and runs tempest.
# Usage: tempest.sh <release> <build_system> <config> <job_type>
set -eux

RELEASE=$1
BUILD_SYS=$2
CONFIG=$3
JOB_TYPE=$4

pushd $WORKSPACE/tripleo-quickstart

bash $WORKSPACE/tripleo-quickstart/quickstart.sh \
    --tags all \
    --config $WORKSPACE/config/general_config/$CONFIG.yml \
    --working-dir $WORKSPACE/ \
    --no-clone \
    --extra-vars @$WORKSPACE/config/general_config/devmode.yml \
    --release "${RELEASE}-tripleo" \
    --extra-vars test_ping=False \
    $VIRTHOST

bash $WORKSPACE/tripleo-quickstart/quickstart.sh \
    --tags all \
    --working-dir $WORKSPACE/ \
    --no-clone \
    --bootstrap \
    --retain-inventory \
    --requirements $WORKSPACE/tripleo-quickstart/quickstart-role-requirements.txt \
    --playbook tempest.yml \
    --extra-vars tempest_source=rdo \
    --extra-vars tempest_format=venv \
    $VIRTHOST

popd
