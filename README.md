# tripleo-quickstart

One of the barriers to entry for trying out TripleO and its derivatives
has been the relative difficulty in getting an environment up quickly.

This set of ansible roles is meant to help.

You will need a host machine with at least **16G** of RAM, preferably
**32G**, with **CentOS 7** installed, and you must be able to `ssh` to
the machine as root without a password from the machine running
ansible.

A quick way to test that your host machine (referred to as `$VIRTHOST`)
is ready to rock is:

    ssh root@$VIRTHOST uname -a

The defaults are meant to "just work", so it is as easy as downloading
and running the quickstart.sh script.

## Getting the script

You can download the `quickstart.sh` script with `wget`:

    wget https://raw.githubusercontent.com/redhat-openstack/tripleo-quickstart/master/quickstart.sh

Alternatively, you can clone this repository and run the script from
there.

## Requirements

You need some software available on your local system before you can run
`quickstart.sh`. You can install the necessary dependencies by running:

    sudo bash quickstart.sh --install-deps

## Deploying

Deploy your virtual environment by running:

    bash quickstart.sh $VIRTHOST

Where `$VIRTHOST` is the name of the host on which you want to install
your virtual triple0 environment. The `quickstart.sh` script will
install this repository along with ansible in a virtual environment on
your Ansible host and run the quickstart playbook. Note, the
quickstart playbook will delete the `stack` user on `$VIRTHOST` and
recreate it.

This script will output instructions at the end to access the deployed
undercloud. If a release name is not given, `mitaka` is used.

## Documentation

Additional documentation is available in the [docs/](docs/) directory.

## Copyright

Copyright 2015-2016 Red Hat, Inc.

Licensed under the Apache License, Version 2.0 (the "License"); you may
not use this file except in compliance with the License. You may obtain
a copy of the License at <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
