=============================================
Overview for the design of tripleo-quickstart
=============================================

One of the barriers to entry for trying out TripleO and its derivatives has
been the relative difficulty in getting an environment up quickly and
understanding the steps required.  The TripleO team has solved these two
fundamental problems with tripleo-quickstart.  This document will
serve as a place to document the high level design of tripleo-quickstart and
how the design solves users problems.

What is tripleo-quickstart?
===========================

When we refer to tripleo-quickstart we often are talking about two separate
projects tripleo-quickstart and tripleo-quickstart-extras. The following is a
brief description of each project.

* **tripleo-quickstart** is an Ansible tool that provisions the virtual guests,
  networking, and other environmental details to enable a kvm guest based
  deployment of TripleO. This is very handy for development, test, or proof of
  concept (POC) deployments.

* **tripleo-quickstart-extras** are a set of composable Ansible roles that can
  be used to configure, deploy, perform post install actions like scale or
  upgrade TripleO. These individual Ansible roles are narrow in scope to do one
  thing and one thing well. The tightly scoped roles also allows smart parts of
  the project to be easily overridden when required. These roles are designed to
  be self documenting and match the official TripleO documentation.

Problems tripleo-quickstart attempts to solve
=============================================
  * Automate the setup and deployment of TripleO
  * Make the deployment as fast as possible
  * Help make the TripleO deployment easier to understand and welcoming to
    newcomers
  * Make a tool that is attractive to OpenStack developers

Scenarios
=========
  #. Jake the OpenStack developer has a test computer, he has
     installed OpenStack with DevStack but is interested in TripleO.
     Jake has some experience with OpenStack but could be considered a
     relative newcomer.
  #. Joan is an experienced OpenStack developer that is looking to develop
     and test her patches to OpenStack in various ways
     and testing environments.

Platform support
================
  * CentOS
  * Red Hat Enterprise Linux
  * Fedora [*]_

TripleO-Quickstart deploys TripleO therefore is also subject to `TripleO's
requirements <https://docs.openstack.org/tripleo-docs/latest/install/
environments/baremetal.html#minimum-system-requirements>`_.

Problem: Automate the setup and deployment of TripleO
=====================================================
There are many tools one can use to automated the deployment
of TripleO, we have chosen `Ansible <https://www.ansible.com/>`_.
The following is a list of design decisions made to solve the problem.

  * Use ansible to provision a libvirt environment in which to deploy OpenStack
    with TripleO
  * Use ansible's composable roles and playbooks to provide a flexible and
    repeatable experience.

  Solve for Scenario #1
    * Focus on virtualization tools available in CentOS and Red Hat Enterprise
      Linux, use libvirt
    * Create an easy to use script to execute tripleo-quickstart e.g.
      quickstart.sh that Jake can just download and execute

      Example:::

        curl -O https://raw.githubusercontent.com/openstack/tripleo-quickstart/master/quickstart.sh
        bash quickstart.sh <host>

  Solve for Scenario #2
    * Allow Joan to use libvirt guests, `bare metal <https://images.rdoproject.org/docs/
      baremetal/>`_, or `OpenStack host clouds <https://images.rdoproject.org/
      docs/ovb/>`_ as test/development environments
    * Allow Joan to pull changes from OpenStack gerrit and build and install the
      patches into the deployment workflow see the following for details :ref:`devmode`.
      the patch(es) into her deployment
    * Allow Joan to test her patch with testing tools like `tempest
      <https://github.com/openstack/tripleo-quickstart-extras/tree/master/
      roles/validate-tempest>`_ or `more basic tests <https://github.com/
      openstack/tripleo-quickstart-extras/tree/master/roles/validate-simple>`_

Problem: Make the deployment as fast as possible
================================================
A deployment of TripleO by default takes more time to install than let's say
`DevStack <https://docs.openstack.org/devstack/latest/>`_.
TripleO is a much more robust and capable deployment so with great power
comes great patience.  People are not always patient so how can
we speed up the deployment? By building preinstalled images we hope to
improve the install time of TripleO.

  * We have created the `build image <https://github.com/openstack/
    tripleo-quickstart-extras/tree/master/roles/build-images>`_ ansible role.
  * The TripleO team hosts TripleO images for the public at
    `ci.centos <https://buildlogs.centos.org/centos/7/cloud/x86_64/tripleo_images/>`_
    and `here <https://images.rdoproject.org/>`_

Problem: Help make the deployment steps easier to understand
============================================================
Deploying any OpenStack distribution **and** understanding what is happening
behind the scenes is not easy for newcomers. Ideally we would have a tool that
prints out the documentation and executes each step for the user.
This way one would have the commands required for a deployment and the context
to give each command meaning.

  Solve for Scenario #1
    * Provision an environment and `create all the scripts and documentation
      <https://github.com/openstack/tripleo-quickstart-extras/tree/master/
      roles/collect-logs>`_ one needs for a successful deployment
      **without** automatically deploying.  Let the user take it **step by
      step** while reading and analyzing the commands with the in-line
      documentation.

  Solve for Scenario #2
    * Again, allow developers to integrate their patches, reference :ref:`devmode`,
      but also allow experienced developers to update the commands, turn on
      debug, hand edit code by `providing the scripts <https://github.com/
      openstack/tripleo-quickstart-extras/blob/master/roles/overcloud-deploy/
      tasks/create-scripts.yml>`_ to deploy **without** automatically
      deploying.

We could translate the deployment steps into ansible and use OpenStack libraries
built for OpenStack like `shade <https://docs.openstack.org/infra/shade/>`_
Both tools are very well designed and would be more than sufficient to deploy
OpenStack with TripleO.  We would be afforded idempotency and other benefits
of ansible, why not use these tools?

  Answer for Scenario #1
    * It's important that users can **directly** map official TripleO
      documentation to the steps automated in this tool.  The official TripleO
      and Red Hat OpenStack Platform both document the deployment using bash
      commands.  New users may not be able to translate ansible to bash and
      vice versa.

  Answer for Scenario #2
    * Not every OpenStack developer is experienced with Ansible.
      For the steps that drive a TripleO deployment it was considered ideal
      to use traditional OpenStack programming languages like bash and python.

To ensure this tool only uses supported OpenStack and TripleO commands and
could provide both scripts and documentation to users,
`jinja templated bash <https://docs.ansible.com/ansible/
playbooks_templating.html>`_ was chosen.

Make a tool that is attractive to OpenStack developers
======================================================
It is critical that OpenStack developers can develop and test their patches
**outside** of the OpenStack CI system in the same way that they are tested
**inside** the CI system, developers need to be able to recreate CI results.
By abstracting out environments but providing the same inputs one can be assured
to get the same results from tripleo-quickstart whether using upstream
OpenStack CI or a local tripleo-quickstart deployment on libvirt.

  Solve for Scenario #2
    * use composable ansible `roles <https://github.com/openstack/
      tripleo-quickstart-extras/tree/master/roles>`_ that have limited scope
      and are reusable. Small tools that do one thing and do one thing well has
      proven to be a robust model.
    * Allow developers to test their patches, reference :ref:`devmode`
    * Allow developers to extend code :ref:`working-with-extras` to
      suit their own needs
    * Allow for multiple tripleo deployments on the same virthost which saves on
      hardware resources.

Footnotes:
==========
.. [*] Fedora may work but is not guaranteed to work as we do not currently
       have a CI system that provides Fedora. Changes to TripleO Quickstart
       are not gated against Fedora hosts or cloud images.
