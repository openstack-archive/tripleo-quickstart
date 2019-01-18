.. include:: ../../README.rst

.. _basic_usage:

Basic usage
===========

Getting the script
------------------

You can download the ``quickstart.sh`` script with ``curl``::

    curl -O https://raw.githubusercontent.com/openstack/tripleo-quickstart/master/quickstart.sh

Alternatively, you can clone this repository and run the script from there.

Requirements
------------

You need some software available on your local system before you can run
``quickstart.sh``. You can install the necessary dependencies by running::

    bash quickstart.sh --install-deps

Deploying with instructions
---------------------------

Deploy your virtual environment by running::

    bash quickstart.sh $VIRTHOST

Where ``$VIRTHOST`` is the name of the host on which you want to install your
virtual triple0 environment. The ``quickstart.sh`` script will install this
repository along with ansible in a virtual environment on your Ansible host and
run the quickstart playbook. Note, the quickstart playbook will delete the
``stack`` user on ``$VIRTHOST`` and recreate it.

This script will output instructions at the end to access the deployed
undercloud. If a release name is not given, ``queens`` is used.

Deploying without instructions
------------------------------
::

    bash quickstart.sh --tags all $VIRTHOST

You may choose to execute an end to end deployment without displaying the
instructions and scripts provided by default.  Using the ``--tags all`` flag
will instruct quickstart to provision the environment and deploy both the
undercloud and overcloud.  Additionally a validation test will be executed to
ensure the overcloud is functional.

Deploying on localhost
----------------------
::

    bash quickstart.sh 127.0.0.2

Please note the following when using quickstart to deploy tripleo directly on
localhost.  Use the loopback address ``127.0.0.2`` in lieu of localhost as
localhost is reserved by ansible and will not work correctly. The deployment
should pass, however you may not be able to ssh to the overcloud nodes
while using the default ssh config file. The ssh config file that is generated
by quickstart e.g. ``~/.quickstart/ssh.config.ansible`` will try to proxy
through the localhost to ssh to the localhost and will cause an error
if ssh is not setup to support it.

Re-Deploying
------------
::

    bash quickstart.sh -X -b $VIRTHOST

Please note that ~/.quickstart folder cannot be reused between deployments. It
has to be removed before executing quickstart.sh again. Using the ``-X`` flag,
the script will remove this directory and create it again.

Note that using ``-b`` flag will also force the creation of the virtualenv
environment and the installation of any requirement.

Enable Developer mode
---------------------

Please refer to
the `OpenStack Documentation
<https://docs.openstack.org/tripleo-docs/latest/contributor/reproduce-ci.html>`_

Feature Configuration and Nodes
-------------------------------

In previous versions of triple-quickstart a config file was used to determine
not only the features that would be enabled in tripleo and openstack but also
the number of nodes to be used. For instance "config/general_config/ha.yml" would
configure pacemaker and ensure three controller nodes were provisioned.  This type
of configuration is now deprecated but will still work through the Queens release.

The feature and node configuration have been separated into two distinct
configuration files to allow users to explicity select the configuration known as
"feature sets" and the nodes to be provisioned.  The feature set configuration
can be found under tripleo-quickstart/config/general_config/ and the node
configuration can be found under tripleo-quickstart/config/nodes/

A more in depth description of the feature sets can be found in the documentation
under :ref:`feature-configuration`

A more in depth description of how to configure nodes can be found in the
documentation under :ref:`node-configuration`

Working With Quickstart Extras
------------------------------

TripleO Quickstart is more than just a tool for quickly deploying a single machine
TripleO instance; it is an easily extensible framework for deploying OpenStack.

For a how-to please see :ref:`working-with-extras`

Setting up libvirt guests only
------------------------------

At times it is useful to only setup or provision libvirt guests without installing any
TripleO code or rpms.  The tripleo-quickstart git repository is designed to provision
libvirt guest environments.  Some may be familiar with an older TripleO tool called
instack-virt-setup, these steps would replace that function.

To deploy the undercloud node uninstalled and empty or blank overcloud nodes
do the following.::

    bash quickstart.sh --tags all --playbook quickstart.yml $VIRTHOST

To only deploy one node, the undercloud node do the following.::

    bash quickstart.sh --tags all --playbook quickstart.yml -e overcloud_nodes="" $VIRTHOST

Documentation
-------------

The full documentation is in the ``doc/source`` directory, it can be built
using::

    tox -e docs
