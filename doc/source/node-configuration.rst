.. _node-configuration:

Node Configuration
=============

You configure the overcloud nodes by placing variable definitions in a
YAML file and passing that to ansible using the ``-N`` command line
option, like this::

    quickstart.sh -N config/nodes/1ctlr_1comp.yml

Setting number and type of overcloud nodes
------------------------------------------

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

      - name: ceph_0
        flavor: ceph

      - name: swift_0
        flavor: objectstorage


Controlling resources
---------------------

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

There is another option ``extradevices`` that can be used to create three
additional blockdevices ``vdb``, ``vdc`` and ``vdd`` per node. By default it
is only enabled on the objectstorage node flavor.

An example
----------

To create a minimal environment that would be unsuitable for deploying
anything real nova instances, you could place something like the
following in ``myconfigfile.yml``::

    undercloud_memory: 8192
    control_memory: 6000
    compute_memory: 2048

    overcloud_nodes:
      - name: control_0
        flavor: control

      - name: compute_0
        flavor: compute

And then pass that to the ``ansible-playbook`` command as described at
the beginning of this document.
