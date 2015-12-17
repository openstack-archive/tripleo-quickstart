#!/bin/bash

set -ex

virtualenv .quickstart --system-site-packages
source .quickstart/bin/activate
pip install -I pbr
pip install git+https://github.com/trown/tripleo-quickstart.git@master#egg=tripleo-quickstart
# tripleo-quickstart requires Ansible 2.0
pip install -I git+https://github.com/ansible/ansible.git@v2.0.0-0.6.rc1#egg=ansible

export ANSIBLE_CONFIG=.quickstart/usr/local/share/tripleo-quickstart/ansible.cfg
export ANSIBLE_INVENTORY=.quickstart/hosts

RELEASE=${1:-liberty}
ansible-playbook -vv .quickstart/usr/local/share/tripleo-quickstart/playbooks/quickstart-$RELEASE.yml
