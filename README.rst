tripleo-quickstart
==================

One of the barriers to entry for trying out TripleO and its
derivatives has been the relative difficulty in getting an
environment up quickly.

This set of ansible roles is meant to help.

You will need a host machine with at least 16G of RAM, preferably 32G,
with CentOS 7 installed, and able to be ssh'd to as root
without password from the machine running ansible.

A quick way to test that your host machine (referred to as `$VIRTHOST`) is
ready to rock is::

    ssh root@$VIRTHOST uname -a

The defaults are meant to "just work", so it is as easy as
downloading and running the quickstart.sh script.

The quickstart.sh script will install this repo along
with ansible in a virtual environment and run the quickstart
playbook. Note, the quickstart playbook will delete the ``stack``
user on the virthost and recreate it.::

    export VIRTHOST='my_test_machine.example.com'

    wget https://raw.githubusercontent.com/redhat-openstack/tripleo-quickstart/master/quickstart.sh
    bash quickstart.sh $VIRTHOST

This script will output instructions at the end to access the
deployed undercloud. If a release name is not given, ``mitaka``
is used.


Documentation
=============

More in-depth documentation is a work in progress. Patches welcome!

It is also possible to pre-download the undercloud.qcow2 image,
and use it for multiple runs. From the machine that will be the
virthost, create a directory for the undercloud image and wget
it. Note, the image location should be world readable since
a ``stack`` user is used for most steps.::

    mkdir -p /usr/share/quickstart_images/mitaka/
    cd /usr/share/quickstart_images/mitaka/
    wget https://ci.centos.org/artifacts/rdo/images/mitaka/delorean/stable/undercloud.qcow2.md5 \
    https://ci.centos.org/artifacts/rdo/images/mitaka/delorean/stable/undercloud.qcow2

    # Check that the md5sum's match (The playbook will also
    # check, but better to know now whether the image download
    # was ok.)
    md5sum -c undercloud.qcow2.md5

Then use the quickstart.sh script with the -u option::

    export VIRTHOST='my_test_machine.example.com'
    export UNDERCLOUD_QCOW2_LOCATION=file:///usr/share/quickstart_images/mitaka/undercloud.qcow2

    wget https://raw.githubusercontent.com/redhat-openstack/tripleo-quickstart/master/quickstart.sh
    bash quickstart.sh -u $UNDERCLOUD_QCOW2_LOCATION $VIRTHOST


To install ``tripleo-quickstart`` yourself instead of via the
quickstart.sh script::

    pip install git+https://github.com/redhat-openstack/tripleo-quickstart.git@master#egg=tripleo-quickstart

Playbooks will be located in either ``/usr/local/share/tripleo-quickstart`` or
in ``$VIRTUAL_ENV/usr/local/share/tripleo-quickstart`` if you have installed in
a virtual environment.

Contributing
============

Bug reports
-----------

If you encounter any problems with ``tripleo-quickstart`` or if you
have feature suggestions, please feel free to open a bug report in 
`our issue tracker`_.

.. _our issue tracker: https://github.com/redhat-openstack/tripleo-quickstart/issues/

Code
----

If you *fix* a problem or implement a new feature, you may submit your
changes via Gerrit.  The ``tripleo-quickstart`` project uses a Gerrit
workflow similar to the `OpenStack Gerrit workflow`_.  We're currently
using review.gerrithub.io_, so you will need to establish an account
there first.

.. _review.gerrithub.io: https://review.gerrithub.io/

Once your gerrithub account is ready,  install the `git-review`_ tool,
then from within a clone of the `tripleo-quickstart` repository run::

    git review -s

After you have made your changes locally, commit them to a feature
branch, and then submit them for review by running::

    git review

Your changes will be tested by our automated CI infrastructure, and
will also be reviewed by other developers.  If you need to make
changes (and you probably will; it's not uncommon for patches to go
through several iterations before being accepted), make the changes on
your feature branch, and instead of creating a new commit, *amend the
existing commit*, making sure to retain the ``Change-Id`` line that
was placed there by ``git-review``::

    git ci --amend

After committing your changes, resubmit the review::

    git review

.. _openstack gerrit workflow: http://docs.openstack.org/infra/manual/developers.html#development-workflow
.. _git-review: http://docs.openstack.org/infra/manual/developers.html#installing-git-review

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
