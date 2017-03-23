#!/bin/bash
# Collect the logs from a CI job

set -eux

# Note(hrybacki): Config used by collect-logs should be the same used by
# TripleO Quickstart during deployment
CONFIG=$1
LOG_ENV=${2:-centosci}
JOB_TYPE=${3:-default}

export ANSIBLE_INVENTORY=$WORKSPACE/hosts
export ANSIBLE_CONFIG=$WORKSPACE/tripleo-quickstart/ansible.cfg
export SSH_CONFIG=$WORKSPACE/ssh.config.ansible
export ANSIBLE_SSH_ARGS="-F ${SSH_CONFIG}"

# (trown) This is so that we ensure separate ssh sockets for
# concurrent jobs. Without this, two jobs running in parallel
# would try to use the same undercloud-stack socket.
socketdir=$(mktemp -d /tmp/sockXXXXXX)
export ANSIBLE_SSH_CONTROL_PATH=$socketdir/%%h-%%r

export ARA_DATABASE="sqlite:///${WORKSPACE}/ara.sqlite"
$WORKSPACE/bin/ara generate html $WORKSPACE/ara

if [ "$JOB_TYPE" = "gate" ]; then
    VERIFY_SPHINX=true
else
    VERIFY_SPHINX=false
fi

bash quickstart.sh \
    --working-dir $WORKSPACE/ \
    --no-clone \
    --bootstrap \
    --retain-inventory \
    --config $WORKSPACE/config/general_config/$CONFIG.yml \
    --playbook collect-logs.yml \
    --extra-vars @$WORKSPACE/config/general_config/${LOG_ENV}-logs.yml \
    --extra-vars artcl_verify_sphinx_build=$VERIFY_SPHINX \
    localhost

