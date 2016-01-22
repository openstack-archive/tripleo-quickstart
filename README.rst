tripleo-quickstart
==================

One of the barriers to entry for trying out TripleO and its
derivatives has been the relative difficulty in getting an
environment up quickly.

This set of ansible roles is meant to help.

You will need a host machine with at least 16G of RAM, preferably 32G,
with CentOS 7 installed, and able to be ssh'd to without password from
the machine running ansible.

The defaults are meant to "just work", so it is as easy as
downloading and running the quickstart.sh script.
This script will install this repo along with ansible in a
virtual environment and run the quickstart playbook::

    export VIRTHOST='my_test_machine.example.com'
    bash <(curl -s https://raw.githubusercontent.com/redhat-openstack/tripleo-quickstart/master/quickstart.sh) [release]

The playbook will output a debug message at the end with instructions
to access the deployed undercloud. If a release name is not given, ``mitaka``
is used.

The install process is not run to completion so that it's easier to clean the
image; to finish the installation, ssh into the undercloud VM and run::

    openstack undercloud install

as the ``stack`` user.

Documentation
=============

More in-depth documentation is a work in progress. Patches welcome!

To install ``tripleo-quickstart`` yourself instead of via the
quickstart.sh script::

    pip install git+https://github.com/redhat-openstacktripleo-quickstart.git@master#egg=tripleo-quickstart

Playbooks will be located in either ``/usr/local/share/tripleo-quickstart`` or
in ``$VIRTUAL_ENV/usr/local/share/tripleo-quickstart`` if you have installed in
a virtual environment.

Installing a specific undercloud image
======================================

Install ``tripleo-quickstart`` as above, then run::

    export VIRTHOST='my_test_machine.example.com'
    export ANSIBLE_CONFIG=$VIRTUAL_ENV/usr/local/share/tripleo-quickstart/ansible.cfg
    export ANSIBLE_INVENTORY=$VIRTUAL_ENV/hosts
    ansible-playbook -vv [path to quickstart-liberty.yml] --extra-vars url=[url]

on your workstation. ``url`` should be the URL of an undercloud machine image,
visible to the virthost machine. For instance, if you have files
undercloud.qcow2 and undercloud.qcow2.md5 in the virthost's /tmp directory, run
the following from your workstation::

    export VIRTHOST='my_test_machine.example.com'
    export ANSIBLE_CONFIG=$VIRTUAL_ENV/usr/local/share/tripleo-quickstart/ansible.cfg
    export ANSIBLE_INVENTORY=$VIRTUAL_ENV/hosts
    ansible-playbook -vv $VIRTUAL_ENV/usr/local/share/tripleo-quickstart/playbooks/quickstart-liberty.yml --extra-vars url=file:///tmp/undercloud.qcow2

Author
======
John Trowbridge

Copyright
=========
Copyright 2015 Red Hat, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
