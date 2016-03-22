#!/bin/bash
# Collect the logs from a CI job

set -eux

cp -f $WORKSPACE/hosts $WORKSPACE/khaleesi/hosts
cp -f $WORKSPACE/ssh.config.ansible $WORKSPACE/khaleesi/ssh.config.ansible

export ANSIBLE_CONFIG=$WORKSPACE/tripleo-quickstart/ansible.cfg
# (trown) I don't totally understand why this is needed here, but activating
# the venv is failing otherwise.
export VIRTUAL_ENV_DISABLE_PROMPT=1
# (trown) In the image build case, we don't have a venv in the workspace.
source $WORKSPACE/bin/activate || true

ansible --version
pushd $WORKSPACE/khaleesi
anscmd="stdbuf -oL -eL ansible-playbook -vvvv"
$anscmd -i hosts --extra-vars @$WORKSPACE/tripleo-quickstart/ci-scripts/provision_centos_settings.yml playbooks/collect_logs.yml
popd
