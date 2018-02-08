.. _environment-configuration:

Environment Configuration
=========================

TripleO-Quickstart has the requirement and capacity to execute in several
different environments and using different types of systems to bootstrap
the environments.

Some known examples of different environments are:

  * upstream OpenStack CI
  * CI CentOS (ci.centos.org)
  * local libvirt environments
  * running OVB based deployments in various clouds
  * Using a CentOS or RHEL qcow2 image without preinstalled OpenStack RPMS.
  * Developer environments with libvirt in privileged mode

Anything defined in an environment configuration file should not impact or
overwrite a variable in a featureset, topology or release configuration file.
There should be no intersection of variables between the three types of
configuration.

You will find environment configuration files under $repo/config/environments.
Some of the environment configuration will be stored in TripleO Quickstart or
TripleO Quickstart Extras, however sometimes the configuration is specific
to CI and may only exist in the environment itself.  For example variables
specific to executing TripleO Quickstart in upstream will live in
https://github.com/openstack-infra/tripleo-ci/tree/master/toci-quickstart

Example Invocation::

    quickstart.sh -E config/environments/default_libvirt.yml $VIRTHOST
