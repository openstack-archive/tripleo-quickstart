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
    bash <(curl -s https://raw.githubusercontent.com/trown/tripleo-quickstart/master/quickstart.sh)

The playbook will output a debug message at the end with instructions
to access the deployed undercloud.

Documentation
=============

More in-depth documentation is a work in progress. Patches welcome!

To install ``tripleo-quickstart`` yourself instead of via the
quickstart.sh script::

    pip install git+https://github.com/trown/tripleo-quickstart.git@master#egg=tripleo-quickstart
    # tripleo-quickstart requires Ansible 2.0
    pip install git+https://github.com/ansible/ansible.git@v2.0.0-0.6.rc1#egg=ansible

Playbooks will be located in either ``/usr/local/share/tripleo-quickstart`` or
in ``$VIRTUAL_ENV/usr/local/share/tripleo-quickstart`` if you have installed in
a virtual environment.

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