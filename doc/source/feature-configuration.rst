.. _feature-configuration:

Feature Configuration
=====================

One can configure the Openstack features installed on either the undercloud
or overcloud by placing variable definitions in a YAML file and passing that
to quickstart using the ``-c`` command line option, like this::

    quickstart.sh -c config/general_config/featureset001.yml

Each feature set can also deploy a customized list of Openstack services. These
services are defined by the tripleo-heat-templates used for the overcloud deployment.
A definition of the services can be found
`here <https://github.com/openstack/tripleo-heat-templates/blob/master/README.rst#service-testing-matrix>`_

Below is a table with various features listed in each row and the features enabled
in each feature set configuration file in each column. When adding new configurations
please consult the following `etherpad <https://etherpad.openstack.org/p/quickstart-featuresets>`_

.. include:: feature-configuration-generated.rst

Note and Known limitation:

 - Featureset037, Overcloud Update:
    - this doesn't change the container image file.
