.. _devmode:

Using Quickstart for Development
================================

TripleO-Quickstart is capable of building a working deployment that
incorporates several upstream changes both for the undercloud and the
overcloud. The only requirement is for the project to be buildable by DLRN_.

We will refer to working with the latest upstream master image and optionally
injecting pending changes as `devmode`.

Quickstart's third party CI is using ``ci-scipts/full-deploy.sh``, however the
invocation is not user friendly. The devmode can be accessed by running::

    ./devmode.sh <virthost>

Available options:

- ``--config <type>``: the configuration to deploy, can be ``minimal``, ``ha``
  or any other node configuration type file from
  ``tripleo-quickstart/config/general_config``
- ``--no-gate``: by default the script tries to recreate an environment with an
  upstream change and asks interactive questions to specify it; this option
  suppresses that function and creates the environment without any extra changes
- ``--working-dir <dir>``: directory where all the temporary run time files are
  stored.
- ``virthost``: the machine to deploy the environment to

The ``devmode.sh`` script uses the ``master-tripleo-ci`` release which in turn
uses the upstream overcloud images that are also being used for the CI jobs.

If the ``--no-gate`` option is absent, the script checks if some environment
variables are present, and asks for user input if undefined. The following
sections include a detailed explanation of each variable and the process of
building and injecting changes.

Gerrit mode
-----------

Use the Gerrit mode to have a change and its "Depends-On:" dependencies
resolved and built. Detailed description about "Depends-On:" is in the `Adding
a Dependency`_ and `Cross-Repository Dependencies`_ section of the OpenStack
Developer's Guide.

.. _`Adding a Dependency`: https://docs.openstack.org/infra/manual/developers.html#adding-a-dependency
.. _`Cross-Repository Dependencies`: https://docs.openstack.org/infra/manual/developers.html#cross-repository-dependencies

The interactive script will ask for the following variables:

- ``GERRIT_HOST``: Any of the common gerrit servers. The choices are restricted
  in the gating role by the ALLOWED_HOSTS_ list.
- ``GERRIT_CHANGE_ID``: The long Change-Id from the commit message, starting
  with `I....`.
- ``GERRIT_BRANCH``: The branch of the change.
- ``GERRIT_PATCHSET_REVISION``: The git hash of the target patchset. Needs to
  be an exact hash, we can't determine the latest yet during runtime.

.. Note:: As there can be multiple changes on different branches with the same
   Change-Id, specifying the branch is mandatory. It's possible in the future
   an enhancement could be made to allow for a just-in-time check for a unique
   Change-Id, thereby allowing us to skip this configuration option.

Zuul mode
---------

The ``devmode.sh`` script can be used with a ``ZUUL_CHANGES`` variable that can
be found in the logs of the upstream CI jobs in the ``_zuul_ansible/vars.yaml``
file. The variable contains the gated change and all the dependent changes that
Zuul processed and resolved.

An example of the variable looks like this::

    ZUUL_CHANGES=openstack/tripleo-heat-templates:master:refs/changes/88/296488/1^openstack/instack-undercloud:master:refs/changes/84/315184/5

Changes are separated by ``^`` and are in the format of
``project:branch:refspec``, a combination which uniquely identifies a Gerrit
change. You can construct your own ``ZUUL_CHANGES`` variable if you want to
test multiple changes that are not properly linked by "Depends-On:" conditions
in the commit messages.

.. Note:: While Zuul only supports "Depends-On:" on the same Gerrit instance,
   the gating role can resolve changes across these different allowed servers
   if you specify part of their name after the Change-Id. For example
   ``Depends-On: I.....@gerrithub`` will make your change depend on the
   specified change from review.gerrithub.io.

.. _ALLOWED_HOSTS: https://github.com/redhat-openstack/ansible-role-tripleo-gate/blob/master/library/jenkins_deps.py#L48-L50

Virthost and Workspace
----------------------

Apart from the variables in either Zuul or Gerrit mode, the script needs a
virthost as the first regular argument to build the environment.

.. Note:: You need to be able to ssh into this machine as root without
   password.

The script uses ``~/.quickstart`` as the default working directory. We store
the various run-time files needed for the deployment and accessing the nodes.
See :ref:`accessing-undercloud` and :ref:`accessing-overcloud` for the details.

It's possible to have more than one parallel working deployment by specifying
different virthosts and working directories for each run.

How Devmode Works
-----------------

The following steps taken by the gates/reproducers compared to a normal
quickstart run:

#. Build RPMs using DLRN_ from the specified upstream or packaging changes. The
   changes can be specified either manually or parsed by either environment
   variables set by Zuul or Jenkins jobs.
#. Create a gating repository that include all the RPMs built.
#. Inject a gating repo during the quickstart run into the undercloud
   and overcloud images.
#. Upgrade all packages that are inside the gating repo.
#. Proceed with the quickstart run as usual.

.. _DLRN: https://github.com/openstack-packages/DLRN

Detailed Package Build and Injection Process
--------------------------------------------

As the devmode bits are dispersed in the code, the exact process is best
understood by looking at the relevant parts of the build-test-packages role and
various quickstart roles for each step:

#. Setting up DLRN and parsing the Jenkins/Zuul changes and building
   the gating repo: build-test-packages_ role.
#. Build individual changes based on the parsed data: dlrn-build.yml_
#. Injecting the repo is triggered when ``compressed_gating_repo`` is set
   during the `libvirt/setup`_ role.
#. The repo injection steps are in `inject_gating_repo.yml`_
#. Creating the repo file and updating the packages are done through the
   ``virt-customize`` command, running `inject_gating_repo.sh`_.

.. _build-test-packages: https://github.com/openstack/tripleo-quickstart-extras/tree/master/roles/build-test-packages
.. _dlrn-build.yml: https://github.com/openstack/tripleo-quickstart-extras/blob/master/roles/build-test-packages/tasks/dlrn-build.yml
.. _`libvirt/setup`: https://github.com/openstack/tripleo-quickstart/blob/b80109f8201b6f3a01987116b785b7ee7f6eae14/roles/libvirt/setup/undercloud/tasks/main.yml#L48-L50
.. _`inject_gating_repo.yml`: https://github.com/openstack/tripleo-quickstart/blob/master/roles/libvirt/setup/undercloud/tasks/inject_gating_repo.yml
.. _`inject_gating_repo.sh`: https://github.com/openstack/tripleo-quickstart/blob/master/roles/libvirt/setup/undercloud/templates/inject_gating_repo.sh.j2
