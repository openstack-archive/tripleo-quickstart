#!/bin/bash

set -ex

virtualenv $HOME/.quickstart --system-site-packages
source $HOME/.quickstart/bin/activate
pushd $HOME/.quickstart
git clone https://github.com/redhat-openstack/tripleo-quickstart.git
pushd tripleo-quickstart

# This is needed explicitly in some cases.
pip install -r requirements.txt

python setup.py install
popd
popd
export ANSIBLE_CONFIG=$HOME/.quickstart/usr/local/share/tripleo-quickstart/ansible.cfg
export ANSIBLE_INVENTORY=$HOME/.quickstart/hosts

echo "ssh_args = -F $HOME/.quickstart/ssh.config.ansible" >> $ANSIBLE_CONFIG

RELEASE=${1:-mitaka}
ansible-playbook -vv .quickstart/usr/local/share/tripleo-quickstart/playbooks/quickstart-$RELEASE.yml

echo "##################################"
echo "Virtual Environment Setup Complete"
echo "##################################"
echo ""
echo "Access the undercloud by:"
echo "ssh -F $HOME/.quickstart/ssh.config.ansible undercloud"
echo ""
echo "Then continue the undercloud install with:"
echo "openstack undercloud install"
