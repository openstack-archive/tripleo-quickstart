#!/bin/bash
# Get a CI node

set -eux

pip install -U ansible==1.9.2 > ansible_build; ansible --version

ansible --version

#Use khaleesi to get a centosci node
pushd khaleesi
cp ansible.cfg.example ansible.cfg
sed -i "s%roles_path = %roles_path = $WORKSPACE/tripleo-quickstart/playbooks/roles:playbooks/roles:%" ansible.cfg
sed -i "s%library = %library = $WORKSPACE/tripleo-quickstart/playbooks/library:%" ansible.cfg
echo "ssh_args = -F $PWD/ssh.config.ansible" >> ansible.cfg
touch ssh.config.ansible

# set the base_dir key in the settings file
sed -i "s%/home/rhos-ci/workspace/trown-poc-quickstart-gate-ha%$WORKSPACE%" \
    $WORKSPACE/tripleo-quickstart/ci-scripts/provision_centos_settings.yml

# get node
set +e
anscmd="stdbuf -oL -eL ansible-playbook -vv"
$anscmd -i local_hosts playbooks/provision.yml \
    --extra-vars @$WORKSPACE/tripleo-quickstart/ci-scripts/provision_centos_settings.yml
# this hack allows us to use the in-tree manual provisioner so we control the hosts file
echo $(awk '/ansible_ssh_host/ {{print $2}}' $WORKSPACE/khaleesi/hosts | cut -d '=' -f2) > $WORKSPACE/virthost
popd