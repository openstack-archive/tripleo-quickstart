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

anscmd="stdbuf -oL -eL ansible-playbook -vv"

pushd $WORKSPACE/tripleo-quickstart

# (trown) This is so that we ensure separate ssh sockets for
# concurrent jobs. Without this, two jobs running in parallel
# would try to use the same undercloud-stack socket.
socketdir=$(mktemp -d /tmp/sockXXXXXX)
export ANSIBLE_SSH_CONTROL_PATH=$socketdir/%%h-%%r

# (trown) I don't totally understand why this is needed here, but activating
# the venv is failing otherwise.
export VIRTUAL_ENV_DISABLE_PROMPT=1
source $WORKSPACE/bin/activate

if [ "$JOB_TYPE" = "gate" ] || [ "$JOB_TYPE" = "periodic" ]; then
    $anscmd -i local_hosts \
    $WORKSPACE/tripleo-quickstart/playbooks/build-images-and-quickstart.yml \
    --extra-vars ansible_python_interpreter=/usr/bin/python \
    --extra-vars virthost=$VIRTHOST \
    --extra-vars local_working_dir=$WORKSPACE/ \
    --extra-vars image_url="file:///var/lib/oooq-images/undercloud.qcow2" \
    --extra-vars artib_release=$RELEASE \
    --extra-vars artib_build_system=$BUILD_SYS \
    --extra-vars @$WORKSPACE/tripleo-quickstart/config/general_config/$CONFIG.yml
elif [ "$JOB_TYPE" = "promote" ]; then
    $anscmd -i local_hosts \
    $WORKSPACE/tripleo-quickstart/playbooks/build-images.yml \
    --extra-vars ansible_python_interpreter=/usr/bin/python \
    --extra-vars virthost=$VIRTHOST \
    --extra-vars local_working_dir=$WORKSPACE/ \
    --extra-vars artib_release=$RELEASE \
    --extra-vars release=$RELEASE \
    --extra-vars artib_build_system=$BUILD_SYS \
    --extra-vars build_system=$BUILD_SYS \
    --extra-vars artib_delorean_hash=$delorean_current_hash \
    --extra-vars publish=true
else
    echo "Job type must be one of gate, periodic, or promote"
    exit 1
fi
