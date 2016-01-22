#!/bin/bash

set -ex

virtualenv $HOME/.quickstart --system-site-packages
source $HOME/.quickstart/bin/activate
pushd $HOME/.quickstart
git clone https://github.com/redhat-openstack/tripleo-quickstart.git
pushd tripleo-quickstart
python setup.py install
popd
popd
export ANSIBLE_CONFIG=$HOME/.quickstart/usr/local/share/tripleo-quickstart/ansible.cfg
export ANSIBLE_INVENTORY=$HOME/.quickstart/hosts

echo "ssh_args = -F $HOME/.quickstart/ssh.config.ansible" >> $ANSIBLE_CONFIG

RELEASE=${1:-mitaka}
ansible-playbook -vv .quickstart/usr/local/share/tripleo-quickstart/playbooks/quickstart-$RELEASE.yml
