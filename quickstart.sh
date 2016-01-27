#!/bin/bash

set -ex

# TODO(trown) this stuff should get moved to a bootstrap function
virtualenv $HOME/.quickstart
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
UNDERCLOUD_QCOW2_LOCATION=${UNDERCLOUD_QCOW2_LOCATION:-https://ci.centos.org/artifacts/rdo/images/$RELEASE/delorean/stable/undercloud.qcow2}

ansible-playbook -vv $HOME/.quickstart/usr/local/share/tripleo-quickstart/playbooks/quickstart.yml \
--extra-vars url=$UNDERCLOUD_QCOW2_LOCATION

set +x

echo "##################################"
echo "Virtual Environment Setup Complete"
echo "##################################"
echo ""
echo "Access the undercloud by:"
echo ""
echo "ssh -F $HOME/.quickstart/ssh.config.ansible undercloud"
echo ""
echo ""
echo "Then continue the undercloud install with:"
echo ""
echo "openstack undercloud install"
echo "source stackrc"
echo ""
echo "##################################"
echo "Virtual Environment Setup Complete"
echo "##################################"
