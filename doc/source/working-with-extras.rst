.. _working-with-extras:

Working With Quickstart Extras
========================

Add-on extras for quickstart are available from the
`Redhat Openstack Github <https://github.com/redhat-openstack/>`_ with the
format ansible-role-tripleo-task-to-perform.

Extras can be installed manually using Python setuptools. TripleO Quickstart
provides an automated system for building the Python virtual environment and
pulling in additional dependencies using ``pip install`` and the
``quickstart-extras-requirements.txt`` file, so we suggest you use that.

If your role is in a git repository use the following syntax and append it to
the end of the ``quickstart-extras-requirements.txt`` file::

    git+https://github.com/organization/ansible-role-example.git/#egg=ansible-role-example

To import a role that you are developing locally use the following syntax::

    file:///home/user/folder/ansible-role-example/#egg=ansible-role-example

Once added to the role requirements file ``quickstart.sh`` will automatically
install the specified extras into ``$WORKSPACE``, which is a Python virtual
environment managed by quickstart. By default this environment will be placed
in ``~/.quickstart`` but you can specify its location using the
``--working-dir`` argument.

To invoke quickstart with a playbook of your own or from a preexisting role run
the following command::

    ./quickstart.sh --requirements $REQUIREMENTS --playbook playbook.yml --working-dir \
$WORKSPACE $VIRTHOST

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

Some extras are meant only to be added to an existing playbook. For example, if
you wanted to perform a pingtest to validate the overcloud you would clone the
ansible-role-tripleo-overcloud-validate repository and then edit
``$WORKSPACE/playbooks/quickstart.yml`` like so::

    - name:  Install undercloud and deploy overcloud
      hosts: undercloud
      gather_facts: no
      roles:
        - tripleo/undercloud
        - tripleo/overcloud
        - tripleo-overcloud-validate

This will perform the pingtest validation after the deployment of the overcloud is finished.
The playbook `quickstart-extras.yml` is the most complete playbook offered by default, it
will perform all tasks up to deployment and testing the overcloud using this same method.

While editing existing playbooks is a good way to become familiar with quickstart for actual usage
it's suggested that you include a default playbook at the start of your own instead of duplicating
it in your extra. The example shown below would provide a fully functioning cloud for the rest of
your playbook to run against::

    - name: Setup the cloud
      include: quickstart-extras.yml
