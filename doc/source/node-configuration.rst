.. _node-configuration:

Node Configuration
==================

This section explains the various ways a user can configure nodes.

Libvirt Node Configuration
--------------------------

You configure the overcloud nodes by placing variable definitions in a
YAML file and passing that to ansible using the ``-N`` command line
option, like this::

    quickstart.sh -N config/nodes/1ctlr_1comp.yml

Setting number and type of overcloud nodes
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``overcloud_nodes`` variable can be used to change the number and
type of nodes deployed in your overcloud. The default
(``config/general_config/minimal.yml``) looks like this::

    overcloud_nodes:
      - name: control_0
        flavor: control
        virtualbmc_port: 6230

      - name: compute_0
        flavor: compute
        virtualbmc_port: 6231

You can use your own config if you want to test a different setup. For
example::

    overcloud_nodes:
      - name: control_0
        flavor: control
        virtualbmc_port: 6230
      - name: control_1
        flavor: control
        virtualbmc_port: 6231
      - name: control_2
        flavor: control
        virtualbmc_port: 6232

      - name: compute_0
        flavor: compute
        virtualbmc_port: 6233

      - name: ceph_0
        flavor: ceph
        virtualbmc_port: 6234

      - name: swift_0
        flavor: objectstorage
        virtualbmc_port: 6235


Controlling resources
~~~~~~~~~~~~~~~~~~~~~

These variables set the resources that will be assigned to a node by
default, unless overridden by a more specific variable:

-  ``default_disk``
-  ``default_memory``
-  ``default_vcpu``

These variables set the resources assigned to the undercloud node:

-  ``undercloud_disk``
-  ``undercloud_memory`` (defaults to **12288**)
-  ``undercloud_vcpu`` (defaults to **4**)

These variables set the resources assigned to controller nodes:

-  ``control_disk``
-  ``control_memory``
-  ``control_vcpu``

These variables control the resources assigned to compute nodes:

-  ``compute_disk``
-  ``compute_memory``
-  ``compute_vcpu``

These variables control the resources assigned to ceph storage nodes:

-  ``ceph_disk``
-  ``ceph_memory``
-  ``ceph_vcpu``

There is another option ``extradisks`` that can be used to create three
additional blockdevices ``vdb``, ``vdc`` and ``vdd`` per node. By default it is
only enabled on the objectstorage node flavor. Note that ironic will pick the
smallest disk available in the node when there are multiple disks attached. You
must either set the same size to all the disks using ``extradisks_size`` or
provide ``root_device_hints`` to set in ironic.

An example
~~~~~~~~~~

To create a minimal environment that would be unsuitable for deploying
anything real nova instances, you could place something like the
following in ``myconfigfile.yml``::

    undercloud_memory: 8192
    control_memory: 6000
    compute_memory: 2048

    overcloud_nodes:
      - name: control_0
        flavor: control
        virtualbmc_port: 6230

      - name: compute_0
        flavor: compute
        virtualbmc_port: 6231

And then pass that to the ``ansible-playbook`` command as described at
the beginning of this document.

Baremetal Node Configuration
----------------------------

Baremetal deployments are unique from libvirt virtual deployments in that
the hardware, the specs, and network settings can not be adjusted via a
configuration file.  These settings for each individual baremetal deployment
are unique and must be stored separately.

What the baremetal node configuration ``baremetal.yml`` does is  essentially
ensuring that no libvirt guests are provisioned setting overcloud_nodes to
null::

    overcloud_nodes:

The pattern and layout for baremetal hardware configuration can be found
in `this doc <https://images.rdoproject.org/docs/baremetal/environment-settings-structure.html>`_

For additional support with baremetal deployments please visit the #oooq
channel on freenode irc.

OpenStack Virtual Baremetal Node Configuration
----------------------------------------------

Using OpenStack Virtual Baremetal is a simple node configuration where the
user needs only to define how many cloud instances to run.

For example, you will find the following config in the node configuration
files::

    # Define the controller node and compute nodes.
    # Create three controller nodes and one compute node.
    node_count: 4

The remaining configuration for the instances like the flavor types are found
in the config/environment/ configuration as this may vary based on your cloud
provider.  For an example please reference `this configuration
<https://github.com/openstack/tripleo-quickstart-extras/blob/master/config/environments/rdocloud.yml#L7-L16>`_
