.. _configuration:

Configuration
=============

The virtual environment deployed by tripleo-quickstart is largely
controlled by variables that get there defaults from the ``common``
role.

You configure tripleo-quickstart by placing variable definitions in a
YAML file and passing that to ansible using the ``-e`` command line
option, like this::

    ansible-playbook playbook.yml -e @myconfigfile.yml

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

Setting number and type of overcloud nodes
------------------------------------------

The ``overcloud_nodes`` variable can be used to change the number and
type of nodes deployed in your overcloud. The default looks like this::

    overcloud_nodes:
      - name: control_0
        flavor: control
      - name: control_1
        flavor: control
      - name: control_2
        flavor: control

      - name: compute_0
        flavor: compute

      - name: ceph_0
        flavor: ceph

Specifying custom heat templates
--------------------------------

The ``overcloud_templates_path`` variable can be used to define a
different path where to get the heat templates. By default this variable
will not be set.

The ``overcloud_templates_repo`` variable can be used to define the
remote repository from where the templates need to be cloned. When this
variable is set, along with ``overcloud_templates_path``, the templates
will be cloned from that remote repository into the target specified,
and these will be used in overcloud deployment.

The ``overcloud_templates_branch`` variable can be used to specify the
branch that needs to be cloned from a specific repository. When this
variable is set, git will clone only the branch specified.

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

Explicit Teardown
-----------------

You can select what to delete prior to the run of quickstart adding a
--teardown (or -T) options with the following parameters:

-  nodes: default, remove only undercloud and overcloud nodes
-  virthost: same as nodes but network setup is deleted too
-  all: same as virthost but user setup in virthost is deleted too
-  none: will not teardown anything (useful for testing multiple actions
   against a deployed overcloud)
