.. _node-configuration:

Getting started with TripleO-Quickstart
=======================================

For the most basic invocations of TripleO-Quickstart please refer to the
:ref:`readme`.  The README will walk you through the basic setup
and execution.

This document will walk through some more basic invocations of
TripleO-Quickstart once you've had success with the steps outlined in the
README.

A step by step deployment with playbooks
----------------------------------------

This section will walk a user through a full deployment step by step by running
ansible playbooks for each major part of the full deployment.  The major steps
include

  * Provision a libvirt environment
  * Install the Undercloud
  * Prepare for the Overcloud deployment
  * Deploy the Overcloud
  * Validate the Overcloud is functional

Provision a libvirt guest environment
-------------------------------------

First things first and in this case we need libvirt guests
setup and running to host the TripleO Undercloud and Overcloud

Example::

    bash quickstart.sh -R master --no-clone --tags all --nodes config/nodes/1ctlr_1comp.yml -p quickstart.yml $VIRTHOST

Note the use of the option `--nodes 1ctlr_1comp.yml`.  The nodes option allows
you to specify the topology of the deployment.  Additional topologies can be
found under tripleo-quickstart/config/nodes.

Reviewing each step in the deployment
-------------------------------------

Once the environment is provisioned a user can ssh into the Undercloud in each
of the following steps and review the bash shell scripts and logs in the home
directory of the Undercloud.

Example::

    ssh -F ~/.quickstart/ssh.config.ansible undercloud

Install the Undercloud
----------------------

Your next step is to install the TripleO Undercloud.  We will use the same
command used in the provisioning step but we'll need to indicate to quickstart
to reuse the ansible inventory file and not to teardown any of the nodes we just
provisioned.

  * ``-I`` : retain the ansible inventory and ssh configuration
  * ``--teardown none`` : do not shutdown any of the libvirt guests

Example::

    bash quickstart.sh -R master --no-clone --tags all --nodes config/nodes/1ctlr_1comp.yml -I --teardown none -p quickstart-extras-undercloud.yml $VIRTHOST

Prepare the TripleO Overcloud for deployment
--------------------------------------------

Once the Undercloud is deployed there are a few additional steps required prior
to deploying the Overcloud.  These steps include

  * configuration preparation
  * container preparation
  * importing Overcloud images
  * ironic introspection of the Overcloud nodes
  * creating OpenStack flavors for profile matching the Overcloud nodes.
  * network configuration
  * SSL configuration

Example::

    bash quickstart.sh -R master --no-clone --tags all --nodes config/nodes/1ctlr_1comp.yml -I --teardown none -p quickstart-extras-overcloud-prep.yml $VIRTHOST

Deploy the TripleO Overcloud
----------------------------

This step will execute the steps required to deploy the Overcloud.  The
Overcloud deployment can be reexecuted as long as the stack is removed prior to
rerunning.

Example::

    bash quickstart.sh -R master --no-clone --tags all --nodes config/nodes/1ctlr_1comp.yml -I --teardown none -p quickstart-extras-overcloud.yml $VIRTHOST

Validate the TripleO Overcloud is functional
--------------------------------------------

This step will run tests to determine the quality of the deployment. The
preferred method to determine the quality is to execute tempest however one can
also deploy a test heat stack on the Overcloud that includes a ping test.

Example::

    bash quickstart.sh -R master --no-clone --tags all --nodes config/nodes/1ctlr_1comp.yml -I --teardown none -p quickstart-extras-validate.yml $VIRTHOST




