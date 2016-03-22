#!/bin/bash
# Return a CI node

set -eux

ansible --version
pushd $WORKSPACE/khaleesi
anscmd="stdbuf -oL -eL ansible-playbook -vv --extra-vars @$WORKSPACE/tripleo-quickstart/ci-scripts/provision_centos_settings.yml"
$anscmd -i local_hosts playbooks/cleanup.yml
popd