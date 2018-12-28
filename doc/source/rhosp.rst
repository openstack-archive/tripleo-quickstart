============================================================================
TripleO deployments and Red Hat OpenStack Platform
============================================================================

Brief Introduction
==================

Production deployments of Red Hat Openstack Platform should be executed by
following the official `Red Hat documentation <https://access.redhat.com/documentation/en/red-hat-openstack-platform/>`_

TripleO-Quickstart is a tool to assist development, test and continuous integration
environments and there is no official support for deploying Red Hat OpenStack
Platform with TripleO-Quickstart.

It is appropriate to use TripleO-Quickstart and the released Red Hat OpenStack
Platform yum repos provided by Red Hat Subscription Manager (RHSM) for development
and test purposes.

Using TripleO-Quickstart with RHSM yum repos
============================================

Under the config/release directory of the TripleO-Quickstart git repository there
is a sample configuration file for RHOSP 11::

    config/release/rhos-11-rhn-baseos-undercloud.yml.example


To use this configuration one must fill out a few values in the configuration::

    rhsm_username: The rhn/rhsm user account name
    rhsm_password: The rhn/rhsm user password
    pool_id: the `product or subscription id [1]

Under the config/environments directory of the TripleO-Quickstart git repository
there is a configuration file for Red Hat Enterprise Linux based deployments::

    config/environments/base_rhel_libvirt.yml

An example invocation of TripleO-Quickstart::

     ./quickstart.sh -R rhos-11-rhn-baseos-undercloud -E baseos_rhel_libvirt --tags all $VIRTHOST


[1] `product subscription documentation <https://access.redhat.com/documentation/en-US/Red_Hat_Subscription_Management/1/html/RHSM/sub-cli.html>`_
