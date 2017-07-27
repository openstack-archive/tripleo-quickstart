TripleO-Validations
===================

Introduction to TripleO-Validations
-----------------------------------

This is a collection of Ansible playbooks to detect and report potential issues
during TripleO deployments.

The validations will help to detect issues early in the deployment process and
prevent field engineers from wasting time on misconfiguration or hardware issues
in their environments.

All validations are written in Ansible and are written in a way that's consumable
by the `Mistral Validation framework` or by Ansible directly. They are available
independently from the UI or the command line client.

* Free software: Apache license
* Source: http://git.openstack.org/cgit/openstack/tripleo-validations
* Bugs: https://bugs.launchpad.net/tripleo/+bugs?field.tag=validations

Running TripleO-Validations using TripleO-Quickstart
----------------------------------------------------

TripleO-Quickstart allows you to run TripleO-Validations through the two ways of
execution (according to the introduction above). The first one is using the
`Mistral framework` and will run all the validations tests by group. The second
one is using `Ansible` directly and the goal is to run negative tests. Both are
launched through shell scripts and these scripts will be available in the
undercloud in the home directory of the unprivileged account created by
TripleO-Quickstart (by default the ``stack`` user).

Running Validations tests through Mistral
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
To enable TripleO-Validations run using `Mistral`, you need to set the
``run_tripleo_validations`` variable to ``True``. By default this variable
is set to ``False``.

By Default, Tripleo-Quickstart won't fail when a validations test will fail.
If you want to disable this behaviour, you just need to set the
``exit_on_validations_failure`` to ``True``.

.. WARNING::
   Note that for most of these validations, a failure does not mean that
   you’ll be unable to deploy or run OpenStack. But it can indicate potential
   issues with long-term or production setups. If you’re running an environment
   for developing or testing TripleO, it’s okay that some validations fail.
   In a production setup they should not.

To run them manually, you can run the ``run-tripleo-validations.sh``. This script
takes the name of validation group as an argument::

    $ bash ./run-tripleo-validations.sh [pre-introspection|pre-deployment|post-deployment]

For more informations about each validations tests owning to these groups, you
can read:

- `pre-introspection group <https://docs.openstack.org/tripleo-validations/latest/validations-pre-introspection-details.html>`__
- `pre-deployment group <https://docs.openstack.org/tripleo-validations/latest/validations-pre-deployment-details.html>`__
- `post-deployment group <https://docs.openstack.org/tripleo-validations/latest/validations-post-deployment-details.html>`__

.. NOTE::
   If you want to know more about running a single or a group of validations, please
   take a look at the `<https://docs.openstack.org/tripleo-docs/latest/install/validations/validations.html>`__

Running Negative tests using Ansible
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
To enable negative tests run using `Ansible`, you need to set the
``run_tripleo_validations_negative_tests`` variable to ``True``. By default
this variable is set to ``False``.
