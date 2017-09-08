============================================================================
Running TripleO Deployments on an OVB Cloud using tripleo-quickstart devmode
============================================================================

Brief Instructions
==================

Requirements:

* Access to an OpenStack Cloud with `OVB support. <http://openstack-virtual-baremetal.readthedocs.io/en/latest/>`_
* V2.0 credentials (rc) file

.. note:: You can download your rc file from Horizon:
   https://<OVB host cloud>/dashboard/project/access_and_security/.
   In the ‘API Access’ tab, click the ‘Download Openstack RC File v2.0’ (not the V3.0 file).
   The RC file will not contain your password when you download it.
   When you source this file, you will be prompted for it.
   To run devmode without interactive prompts, edit the rc file to contain your password.

Check out the tripleo-quickstart git repository and execute::

    bash quickstart.sh --install-deps

You are now ready to execute the deployment::

    source openstack_rc.sh
    bash devmode.sh --no-gate --ovb

This will deploy:
 - 1 undercloud instance
 - 1 BMC instance
 - 2 baremetal overcloud instances (minimal  1 controller, 1 compute deployment
   - with pacemaker - deployed with public-bond network isolation)

In-Depth Instructions
=====================

Key file
--------

A key file is required to ssh to the undercloud. By default, $USER/.ssh/id_rsa will be used.

.. note:: The user may change which ssh key is used by setting the variable ``existing_key_location``
          in the configuration files.


Testing patches
---------------

Running devmode with OVB includes the original devmode functionality to test patches.
If -n for "no gate" is *not* present the user will be presented with questions
regarding the patch in question. This works in the same way as libvirt and
instructions can be found in :ref:`devmode`.


Additional OVB-related devmode options
--------------------------------------

Environment clean up
````````````````````

Use the flag (--delete-all-stacks | -d)

Individual tenants have limited quotas and therefore it is useful to remove existing
stacks and key pairs from the tenant before deploying again.::

    ./devmode.sh --ovb --delete-all-stacks

Passing this option will walk through the following steps:

* openstack stack list
    *  to find all stacks in ``*_COMPLETE`` or ``CREATE_FAILED`` state.
       Note that if a stack is in DELETE_FAILED state, this stack will need manual
       intervention to remove it.
* openstack stack delete $STACK
    *  to delete the existing stacks in those states
* nova keypair-delete
    *  to delete the key pair associated with the stack


Alternative configurations
``````````````````````````

Configuration files contain settings to determine:

* how OVB will deploy the base stack
* how the undercloud and overcloud will be deployed and installed

By default, the *ovb-minimal-pacemaker-public-bond* config file is used.
You can deploy a different configuration by setting::

    export CONFIG=<config file name>

Example::

    export CONFIG=ovb-ha-multiple-nics

This will use the alternative config file available in
tripleo-quickstart-extras/config/general-config to deploy HA (three controllers)
overcloud with multiple-nics network isolation.


