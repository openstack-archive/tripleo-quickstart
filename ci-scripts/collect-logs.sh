#!/bin/bash
# Collect the logs from a CI job

set -eux

git clone https://github.com/redhat-openstack/ansible-role-tripleo-collect-logs.git \
    $WORKSPACE/tripleo-quickstart/playbooks/roles/collect-logs

export ANSIBLE_INVENTORY=$WORKSPACE/hosts
export ANSIBLE_CONFIG=$WORKSPACE/tripleo-quickstart/ansible.cfg
# (trown) I don't totally understand why this is needed here, but activating
# the venv is failing otherwise.
export VIRTUAL_ENV_DISABLE_PROMPT=1
source $WORKSPACE/bin/activate

cat > collect-logs.yaml << EOY
---
- name: Gather logs
  hosts: all:!localhost
  roles:
    - collect-logs
EOY

anscmd="stdbuf -oL -eL ansible-playbook -vvvv"
$anscmd collect-logs.yaml -e @$WORKSPACE/tripleo-quickstart/ci-scripts/centos_log_settings.yml
