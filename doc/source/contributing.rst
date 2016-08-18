Contributing
============

Bug reports
-----------

If you encounter any problems with ``tripleo-quickstart`` or if you have
feature suggestions, please feel free to open a bug report in our `issue
tracker <https://bugs.launchpad.net/tripleo-quickstart>`__.

Code
----

If you *fix* a problem or implement a new feature, you may submit your
changes via Gerrit. The ``tripleo-quickstart`` project uses the
`OpenStack Gerrit
workflow <http://docs.openstack.org/infra/manual/developers.html#development-workflow>`__.

You can anonymously clone the repository via
``git clone https://git.openstack.org/openstack/tripleo-quickstart.git``

If you wish to contribute, you'll want to get setup by following the
documentation available at `How To
Contribute <https://wiki.openstack.org/wiki/How_To_Contribute>`__.

Once you've cloned the repository using your account, install the
`git-review <http://docs.openstack.org/infra/manual/developers.html#installing-git-review>`__
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
