========================
Team and repository tags
========================

.. image:: https://governance.openstack.org/tc/badges/tripleo-quickstart.svg
    :target: https://governance.openstack.org/tc/reference/tags/index.html

.. Change things from this point on

tripleo-quickstart
==================

An up-to-date HTML version is available on docs.openstack.org_.

.. _docs.openstack.org: https://docs.openstack.org/tripleo-quickstart/latest/

Release notes for the project can be found at:
https://docs.openstack.org/releasenotes/tripleo-quickstart/

One of the barriers to entry for trying out TripleO and its derivatives has
been the relative difficulty in getting an environment up quickly.

This set of ansible roles is meant to help.

Quickstart's default deployment method uses a physical machine, which is
referred to as ``$VIRTHOST`` throughout this documentation. On this physical
machine Quickstart sets up multiple virtual machines (VMs) and virtual networks
using libvirt.

One of the VMs is set up as **undercloud**, an all-in-one OpenStack cloud used
by system administrators to deploy the **overcloud**, the end-user facing
OpenStack installation, usually consisting of multiple VMs.

You will need a ``$VIRTHOST`` with at least **16 GB** of RAM, preferably **32
GB**, and you must be able to ``ssh`` to the virthost machine as root without a
password from the machine running ansible.  Currently the virthost machine must
be running a recent Red Hat-based Linux distribution (CentOS 7.x, RHEL 7.x).
Other distributions could work but will not be supported with out CI validation.

..  note::
    Running quickstart.sh commands as root is not suggested or supported.

The SSH server on your ``$VIRTHOST`` must be accessible via public keys for
both the root and stack users.

A quick way to test that root to your virthost machine is ready to rock is::

    ssh root@$VIRTHOST uname -a

The ``stack`` user is not added until the quickstart deploy runs, so this cannot
be tested in advance.  However, if you lock down on a per-user basis, ensure
``AllowUsers`` includes ``stack``.

Timeouts can be an issue if the SSH server is configured to disconnect users
after periods of inactivity.  This can be addressed for example by::

    ClientAliveInterval 120
    ClientAliveCountMax 720

The quickstart defaults are meant to "just work", so it is as easy as
downloading and running the ``quickstart.sh`` script.

Copyright
---------

Copyright 2015-2016 Red Hat, Inc.

Licensed under the Apache License, Version 2.0 (the "License"); you may
not use this file except in compliance with the License. You may obtain
a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
