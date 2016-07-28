# tripleo-quickstart

One of the barriers to entry for trying out TripleO and its derivatives
has been the relative difficulty in getting an environment up quickly.

This set of ansible roles is meant to help.

You will need a host machine (referred to as `$VIRTHOST`) with at least **16G**
of RAM, preferably **32G**, and you must be able to `ssh` to the virthost
machine as root without a password from the machine running ansible. Currently
the virthost machine must be running a recent Red Hat-based Linux distribution
(CentOS 7, RHEL 7, Fedora 22 - only CentOS 7 is currently tested), but we hope to
add support for non-Red Hat distributions too.

A quick way to test that your virthost machine is ready to rock is:

    ssh root@$VIRTHOST uname -a

The defaults are meant to "just work", so it is as easy as downloading
and running the quickstart.sh script.

## Getting the script

You can download the `quickstart.sh` script with `wget`:

    wget https://raw.githubusercontent.com/openstack/tripleo-quickstart/master/quickstart.sh

Alternatively, you can clone this repository and run the script from
there.

## Requirements

You need some software available on your local system before you can run
`quickstart.sh`. You can install the necessary dependencies by running:

    bash quickstart.sh --install-deps

## Deploying with instructions

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

## Deploying without instructions

    bash quickstart.sh --tags all $VIRTHOST

You may choose to execute an end to end deployment without displaying
the instructions and scripts provided by default.  Using the "--tags all"
flag will instruct quickstart to provision the environment and deploy
both the undercloud and overcloud.  Additionally a validation test will
be executed to ensure the overcloud is functional.

## Deploying on localhost

    bash quickstart.sh localhost

Please note the following when using quickstart to deploy tripleo directly on localhost.
The deployment should pass, however you may not be able to ssh to the overcloud nodes while
using the default ssh config file. The ssh config file that is generated by quickstart
e.g. ~/.quickstart/ssh.config.ansible will try to proxy through the localhost to ssh
to the localhost and will cause an error if ssh is not setup to support it.  An alternative
workflow is being tested and can be found under tripleo-quickstart/ci-scripts/usbkey/.

## Enable Developer mode

If you are working on TripleO upstream development, and need to reproduce
what runs in tripleo-ci, you will want to use developer mode.

This will fetch the images produced by tripleo-ci instead of the ones produced
by RDO. The incanation for a job using the quickstart defaults other than
developer mode would be:

    bash quickstart.sh \
            --extra-vars @config/general_config/devmode.yml \
            --release master-tripleo \
            $VIRTHOST

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
