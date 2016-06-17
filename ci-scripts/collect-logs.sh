#!/bin/bash
# Collect the logs from a CI job

set -eux

export ANSIBLE_INVENTORY=$WORKSPACE/hosts
export ANSIBLE_CONFIG=$WORKSPACE/tripleo-quickstart/ansible.cfg
export SSH_CONFIG=$WORKSPACE/ssh.config.ansible
export ANSIBLE_SSH_ARGS="-F ${SSH_CONFIG}"

# (trown) This is so that we ensure separate ssh sockets for
# concurrent jobs. Without this, two jobs running in parallel
# would try to use the same undercloud-stack socket.
socketdir=$(mktemp -d /tmp/sockXXXXXX)
export ANSIBLE_SSH_CONTROL_PATH=$socketdir/%%h-%%r

bash $WORKSPACE/tripleo-quickstart/quickstart.sh \
    --working-dir $WORKSPACE/ \
    --no-clone \
    --bootstrap \
    --retain-inventory \
    --requirements $WORKSPACE/tripleo-quickstart/quickstart-role-requirements.txt \
    --config $WORKSPACE/config/general_config/centosci-logs.yml \
    --playbook collect-logs.yml \
    localhost
