# tripleo-quickstart

One of the barriers to entry for trying out TripleO and its
derivatives has been the relative difficulty in getting an
environment up quickly.

This set of ansible roles is meant to help.

You will need a host machine with at least 16G of RAM, preferably 32G,
with CentOS 7 installed, and able to be ssh'd to without password from
the machine running ansible.

The defaults are meant to "just work", so assuming you
have ansible 2.0 installed it is as easy as:

```bash
    export TEST_MACHINE='my_test_machine.example.com'
    ansible-playbook playbooks/quickstart.yml
```

The playbook will output a debug message at the end with instructions
to access the deployed undercloud.

If you need to install ansible 2.0, this is what I used in testing:

```bash
    git clone https://github.com/ansible/ansible.git
    cd ansible
    git checkout v2.0.0-0.6.rc1
    git submodule update --init --recursive
    virtualenv .venv --system-site-packages
    source .venv/bin/activate
```

## Documentation

More in-depth documentation is a work in progress. Patches welcome!

### Author
John Trowbridge

### Copyright
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