.. _working-with-extras:

Working With Quickstart Extras
==============================

There are several additional roles compatible with tripleo-quickstart that
extend the capability of TripleO Quickstart beyond setting up the basic
deployment structure on a virthost. There are roles for doing end-to-end
deployments and deployment validation both for virthost and baremetal machines
and a few auxiliary roles for doing CI related tasks.

These roles are hosted at the tripleo-quickstart-extras_ repository.

.. _tripleo-quickstart-extras: http://git.openstack.org/cgit/openstack/tripleo-quickstart-extras/

Extras can be installed manually using Python setuptools, but ``quickstart.sh``
provides an automated system for building the Python virtual environment and
pulling in additional dependencies using ``pip install`` and the
``quickstart-extras-requirements.txt`` file.

To run a full end-to-end deployment including verification, add these command
line options when running ``quickstart.sh``::

    --tags all

See ``quickstart.sh --help`` for a full list of options, but here is a full
example using some common developer settings::

    ./quickstart.sh --requirements quickstart-extras-requirements.txt \
                    --tags all \
                    --teardown all \
                    --release master \
                    --no-clone \
                    --clean \
                    --config config/general_config/pacemaker.yml \
                    virthost.example.com

This uses the currently cloned tripleo-quickstart repository instead of
re-cloning it in the working directory, doing the following:

* deletes the working directory at `~/.quickstart`
* this forces quickstart to create the virtual environment and redownload all
  the requirements fresh, including the extras
* it does a thorough cleanup of the `virthost.example.com` machine,
  reinstalling libvirt, deleting networks and VMs
* downloads the master image and creates new VMs based that
* deploys both the undercloud and the overcloud
* verifies the deployed environment in a quick and simple way

Developing new roles
--------------------

Developing new roles is possible by submitting new reviews for this repo, or
creating it anywhere and adding a reference to the end of the
``quickstart-extras-requirements.txt`` file::

    git+https://github.com/organization/ansible-role-example.git/#egg=ansible-role-example

To import a role that you are developing locally use the following syntax::

    file:///home/user/folder/ansible-role-example/#egg=ansible-role-example

Once added to the role requirements file ``quickstart.sh`` will automatically
install the specified extras into the local working directory, which is a
Python virtual environment managed by quickstart. By default this environment
will be placed in ``~/.quickstart`` but you can specify its location using the
``--working-dir`` argument.

To invoke quickstart with a playbook of your own or from a preexisting role run
the following command::

    ./quickstart.sh --requirements $REQUIREMENTS --playbook playbook.yml \
                    --working-dir $WORKSPACE $VIRTHOST

If the virtual environment in ``$WORKSPACE`` has not
already been setup then ``quickstart.sh`` will create it and install all the extras.
This will only happen the first time you run quickstart against that workspace. If you
need to add more dependencies or update existing ones, source the virtual
and then run the ``setup.py`` for the role::

    source $WORKSPACE/bin/activate
    cd $ROLE
    python setup.py install

Deleting the environment and allowing quickstart to regenerate it entirely also works.
Both ``$REQUIREMENTS`` and ``$WORKSPACE`` should be absolute paths.

The playbook ``quickstart-extras.yml`` is the most complete playbook offered by default, it
will perform all tasks up to deployment and testing the overcloud using this same method.

While editing existing playbooks is a good way to become familiar with quickstart for actual usage
it's suggested that you include a default playbook at the start of your own instead of duplicating
it in your extra. The example shown below would provide a fully functioning cloud for the rest of
your playbook to run against::

    - name: Setup the cloud
      include_tasks: quickstart-extras.yml
