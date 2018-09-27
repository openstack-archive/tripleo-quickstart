.. _node-configuration:

Getting started with TripleO-Quickstart
=======================================

For the most basic invocations of TripleO-Quickstart please refer to the
:ref:`basic_usage`.  This quide will walk you through the basic setup
and execution.

This document will walk through some more basic invocations of
TripleO-Quickstart once you've had success with the steps outlined in the
guide.

A step by step deployment with playbooks
----------------------------------------

This section will walk a user through a full deployment step by step by running
ansible playbooks for each major part of the full deployment.  The major steps
include:

* Provision a libvirt environment
* Install the Undercloud
* Prepare for the Overcloud deployment
* Deploy the Overcloud
* Validate the Overcloud is functional

Provision a libvirt guest environment
-------------------------------------

First things first and in this case we need libvirt guests
setup and running to host the TripleO Undercloud and Overcloud

.. note:: By default, Quickstart builds the guests' images using qemu
   emulation (``LIBGUESTFS_BACKEND_SETTINGS=force_tcg``), which is slow
   but just works. In order to enable KVM acceleration, use
   ``export LIBGUESTFS_BACKEND_SETTINGS=network_bridge=virbr0``.
   It may be like a 4 times faster to build VM images in that mode,
   except that you may be hit by bug1743749_.

   .. _bug1743749: https://bugs.launchpad.net/tripleo/+bug/1743749

Example::

    export LIBGUESTFS_BACKEND_SETTINGS=network_bridge=virbr0
    bash quickstart.sh -R master --no-clone --tags all \
        --nodes config/nodes/1ctlr_1comp.yml -p quickstart.yml $VIRTHOST

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
provisioned:

* ``-I`` : retain the ansible inventory and ssh configuration
* ``--teardown none`` : do not shutdown any of the libvirt guests

Example::

    bash quickstart.sh -R master --no-clone --tags all --nodes config/nodes/1ctlr_1comp.yml \
        -I --teardown none -p quickstart-extras-undercloud.yml $VIRTHOST

Prepare the TripleO Overcloud for deployment
--------------------------------------------

Once the Undercloud is deployed there are a few additional steps required prior
to deploying the Overcloud.  These steps include:

* configuration preparation
* container preparation
* importing Overcloud images
* ironic introspection of the Overcloud nodes
* creating OpenStack flavors for profile matching the Overcloud nodes.
* network configuration
* SSL configuration

Example::

    bash quickstart.sh -R master --no-clone --tags all --nodes config/nodes/1ctlr_1comp.yml \
        -I --teardown none -p quickstart-extras-overcloud-prep.yml $VIRTHOST

Deploy the TripleO Overcloud
----------------------------

This step will execute the steps required to deploy the Overcloud.  The
Overcloud deployment can be reexecuted as long as the stack is removed prior to
rerunning.

Example::

    bash quickstart.sh -R master --no-clone --tags all --nodes config/nodes/1ctlr_1comp.yml \
        -I --teardown none -p quickstart-extras-overcloud.yml $VIRTHOST

Validate the TripleO Overcloud is functional
--------------------------------------------

This step will run tests to determine the quality of the deployment. The
preferred method to determine the quality is to execute tempest however one can
also deploy a test heat stack on the Overcloud that includes a ping test.

Example::

    bash quickstart.sh -R master --no-clone --tags all --nodes config/nodes/1ctlr_1comp.yml \
        -I --teardown none -p quickstart-extras-validate.yml $VIRTHOST

Using tags to atomically execute specific phases of the deployment
------------------------------------------------------------------

Developers and testers may be interested in only running discrete tasks in an
atomic fashion. Ansible offers an additional powerful way to control the flow
of execution via ansible tags.
A TripleO-Quickstart with TripleO-Quickstart-Extras deployment can be driven
with tags by using the main playbook ``quickstart-extras.yml``, which contains
the four playbooks mentioned above.
The specific tags that help users to control the workflow are:

  * In ``quickstart.yml``:

    * provision
    * environment
    * libvirt
    * undercloud-inventory

  * In ``quickstart-extras-undercloud.yml``:

    * freeipa-setup
    * undercloud-setup
    * undercloud-deploy

  * In ``quickstart-extras-overcloud-prep.yml``:

    * overcloud-prep-config
    * overcloud-prep-containers
    * overcloud-prep-images
    * overcloud-prep-flavors
    * overcloud-prep-network
    * overcloud-ssl

  * In ``quickstart-extras-overcloud.yml``:

    * overcloud-deploy
    * overcloud-inventory
    * overcloud-check

  * In ``quickstart-extras-validate.yml``:

    * overcloud-validate

For example, a user may want to only provision their environment:::

    $HOMEDIR/tripleo-quickstart/quickstart.sh \
      --bootstrap \
      --no-clone \
      --working-dir $WORKDIR \
      --config $HOMEDIR/workdir/config.yml \
      --nodes  $HOMEDIR/workdir/nodes.yml \
      --playbook quickstart-extras.yml \
      --teardown "all" \
      --tags "provision" \
      --release master \
      $VIRTHOST

The option ``--tags "provision"`` will execute JUST the provision task on the
``$VIRTHOST`` machine so that a developer, for example, will be able to act on
the ``undercloud.cow2`` image placed in this path:::

    [root@VIRTHOST ~]# ls -la /var/cache/tripleo-quickstart/images/
    total 11889496
    drwxrwxr-x. 2 stack stack       4096 12 giu 12.42 .
    drwxrwxr-x. 3 stack stack         20 30 mag 10.46 ..
    -rw-rw-r--. 1 stack stack 2891579392 12 giu 12.42 0d2952297e7c562b7e82739e0ad162e9.qcow2
    lrwxrwxrwx. 1 stack stack         75 12 giu 12.42 latest-undercloud.qcow2 -> /var/cache/tripleo-quickstart/images/0d2952297e7c562b7e82739e0ad162e9.qcow2

Then it is possible to continue the deployment, but the command line must be
different, it must contain options to preserve what was made before.
Like this:::

    $HOMEDIR/tripleo-quickstart/quickstart.sh \
      --retain-inventory \
      --teardown none \
      --ansible-debug \
      --no-clone \
      --working-dir /path/to/workdir \
      --config /path/to/config.yml \
      --nodes /path/to/nodes.yml \
      --playbook quickstart-extras.yml \
      --release master \
      --tags "environment" \
      $VIRTHOST

The two main options here are ``--retain-inventory`` which keep all the
previously generated configurations (hosts and ssh files) and
``--teardown none`` which will preserve any previously created virtual machine.
At this point we will be able to list virtual machines as unprivileged user
stack on the ``$VIRTHOST``:::

    [stack@had-05 ~]$ virsh list
     Id    Name                           State
    ----------------------------------------------------

It is also possible to use more than a tag in a single run, like in this case:::

    $HOMEDIR/tripleo-quickstart/quickstart.sh \
      --retain-inventory \
      --teardown none \
      --working-dir /path/to/workdir \
      --config /path/to/config.yml \
      --nodes /path/to/nodes.yml \
      --playbook quickstart-extras.yml \
      --release $RELEASE \
      --tags "libvirt,undercloud-inventory" \
      $VIRTHOST

In which basically we move on with the deployment, launching the libvirt setup
on the remote host that will deploy the undercloud virtual machine and get its
IP address to be able to include it inside the inventory.
At the end of these steps we will have all the virtual machines prepared, with
the undercloud already running:::

    [stack@had-05 ~]$ virsh list --all
     Id    Name                           State
    ----------------------------------------------------
     2     undercloud                     running
     -     compute_0                      shut off
     -     compute_1                      shut off
     -     control_0                      shut off
     -     control_1                      shut off
     -     control_2                      shut off

And in addition the ``hosts`` file inside the working directory will be
populated with the new data coming from the newly installed undercloud machine,
making us able to access it like this:::

    ssh -F /path/to/workdir/ssh.config.ansible undercloud

At this point we're able to proceed with the undercloud configuration part,
following the same approach and using the tags that are relevant to this
specific phase. Looking at ``quickstart-extras-undercloud.yml`` playbook the
tags for our purpose are ``undercloud-setup`` and ``undercloud-deploy``, so
the command line will be:::

    $HOMEDIR/tripleo-quickstart/quickstart.sh \
      --retain-inventory \
      --teardown none \
      --working-dir /path/to/workdir \
      --config /path/to/config.yml \
      --nodes /path/to/nodes.yml \
      --playbook quickstart-extras.yml \
      --release $RELEASE \
      --tags "undercloud-setup,undercloud-deploy" \
      $VIRTHOST

While the command ends, the user will be able to act on the undercloud and
then when, everything is ready on his side, proceed with the further steps at
the same, atomic, way.
