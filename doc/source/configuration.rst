.. _configuration:

Configuration
=============

The virtual environment deployed by tripleo-quickstart is largely
controlled by variables that get there defaults from the ``common``
role.

You configure tripleo-quickstart by placing variable definitions in a
YAML file and passing that to ansible using the ``-e`` command line
option, like this::

    ansible-playbook playbook.yml -e @/path/myconfigfile.yml

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

Explicit Teardown
-----------------

You can select what to delete prior to the run of quickstart adding a
--teardown (or -T) options with the following parameters:

-  nodes: default, remove only undercloud and overcloud nodes
-  virthost: same as nodes but network setup is deleted too
-  all: same as virthost but user setup in virthost is deleted too
-  none: will not teardown anything (useful for testing multiple actions
   against a deployed overcloud)

Undercloud customization
------------------------

You can perform extra undercloud customization steps, using a script
that will be applied with ``virt-customize`` on the final undercloud
image. To allow that, you need to pass the ``undercloud_customize_script``
var, that needs to point to an script living on your filesystem.
That script will be copied to working directory, and applied on the
undercloud. The script can be in Jinja template format, so you can benefit
from ansible var substitutions.

Overcloud customization
-----------------------

You can perform extra overclud customization steps, using a script
that will be applied with ``virt-customize`` on the overcloud-full
image. To allow that, you need to pass the ``overcloud_customize_script``
var, that needs to point to an script living on your filesystem.
That script will be copied to working directory, and applied on the
overcloud. The script can be in Jinja template format, so you can benefit
from ansible var substitutions.

Consuming external images
-------------------------

In the usual workflow, tripleo-quickstart relies on the overcloud
and agent images that are shipped in the undercloud. But for certain
types of tests, it is useful to provide your own images.
To achieve that, set the ``use_external_images`` to True. This will
cause to inject all the images listed in the ``inject_images`` list
into the undercloud, so the system can use it.
Please note that you also need to define all the images you want to
fetch, using the ``images`` setting. You will need to define the name
of the image, the url where to get it, and the image type (qcow2, tar).
As a reference, please look at the `config <http://git.openstack.org/cgit/openstack/tripleo-quickstart/tree/config/release/master-tripleo-ci.yml>`_

Consuming external/custom vmlinuz and initrd for undercloud
-----------------------------------------------------------

By default, the kernel executable and initial rootfs for an undercloud VM
are extracted from the overcloud image. In order to switch to custom
``undercloud_custom_initrd`` and ``undercloud_custom_vmlinuz`` images,
set the ``undercloud_use_custom_boot_images`` to True.
