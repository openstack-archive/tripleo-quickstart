#!/bin/bash

set -ex

virtualenv .quickstart --system-site-packages
source .quickstart/bin/activate
pushd .quickstart
git clone https://github.com/redhat-openstack/tripleo-quickstart.git
pushd tripleo-quickstart
python setup.py install
popd
popd
export ANSIBLE_CONFIG=.quickstart/usr/local/share/tripleo-quickstart/ansible.cfg
export ANSIBLE_INVENTORY=.quickstart/hosts

echo "ssh_args = -F $PWD/.quickstart/ssh.config.ansible" >> $ANSIBLE_CONFIG

RELEASE=${1:-liberty}
ansible-playbook -vv .quickstart/usr/local/share/tripleo-quickstart/playbooks/quickstart-$RELEASE.yml
