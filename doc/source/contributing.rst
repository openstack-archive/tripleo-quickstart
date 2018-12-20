Contributing
============

Bug reports
-----------

If you encounter any problems with ``tripleo-quickstart`` or if you have
feature suggestions, please feel free to open a bug report in our `issue
tracker <https://bugs.launchpad.net/tripleo/+filebug>`__.  Please add the tag
"quickstart" to the bug.

Code
----

Local testing
`````````````

Before submitting code to Gerrit you *should* do at least some minimal local
testing, like running ``tox -e linters``. This could be automated if you
activate `pre-commit <https://pre-commit.com/>`__ hooks::

    pip install --user pre-commit
    # to enable automatic run on commit:
    pre-commit install --install-hooks
    # to uninstall hooks
    pre-commit uninstall

Please note that the pre-commit feature is available only on repositories that
do have `.pre-commit-config.yaml <https://github.com/openstack/tripleo-quickstart-extras/blob/master/.pre-commit-config.yaml>`__ file.

Running ``tox -e linters`` is recommended as it may include additional linting
commands than just pre-commit. So, if you run tox you don't need to run
pre-commit manually.

Implementation of pre-commit is very fast and saves a lot of disk space
because internally it does cache any linter-version and reuses it between
repositories, as opposed to tox which uses environments unique to each
repository (usually more than one). Also by design pre-commit always pins
linters, making less like to break code because linter released new version.

Another reason why pre-commit is very fast is because it runs only
on modified files. You can force it to run on the entire repository via
`pre-commit run -a` command.

Upgrading linters is done via ``pre-commit autoupdate`` but this should be
done only as a separate change request.

Submitting code
```````````````
If you *fix* a problem or implement a new feature, you may submit your
changes via Gerrit. The ``tripleo-quickstart`` project uses the
`OpenStack Gerrit
workflow <https://docs.openstack.org/infra/manual/developers.html#development-workflow>`__.

You can anonymously clone the repository via
``git clone https://git.openstack.org/openstack/tripleo-quickstart.git``

If you wish to contribute, you'll want to get setup by following the
documentation available at `How To
Contribute <https://wiki.openstack.org/wiki/How_To_Contribute>`__.

Developers are encouraged to install `pre-commit <https://pre-commit.com/#install>`__ in order
to auto-perform a minimal set of checks on commit.

Once you've cloned the repository using your account, install the
`git-review <https://docs.openstack.org/infra/manual/developers.html#installing-git-review>`__
tool, then from the ``tripleo-quickstart`` repository run::

    git review -s

After you have made your changes locally, commit them to a feature
branch, and then submit them for review by running::

    git review

Your changes will be tested by our automated CI infrastructure, and will
also be reviewed by other developers. If you need to make changes (and
you probably will; it's not uncommon for patches to go through several
iterations before being accepted), make the changes on your feature
branch, and instead of creating a new commit, *amend the existing
commit*, making sure to retain the ``Change-Id`` line that was placed
there by ``git-review``::

    git ci --amend

After committing your changes, resubmit the review::

    git review
