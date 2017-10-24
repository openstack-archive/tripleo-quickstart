.. _accessing-undercloud:

Accessing the Undercloud
========================

Access via the CLI
-------------------

When your deployment is complete, you will find a file named
``ssh.config.ansible`` located inside your ``local_working_dir`` (which
defaults to ``$HOME/.quickstart``). This file contains configuration
settings for ssh to make it easier to connect to the undercloud host.
You use it like this::

    ssh -F $HOME/.quickstart/ssh.config.ansible undercloud

This will connect you to the undercloud host as the ``stack`` user::

    [stack@undercloud ~]$

Once logged in to the undercloud, you can source the ``stackrc`` file if
you want to access undercloud services::

    [stack@undercloud ~]$ . stackrc
    [stack@undercloud ~]$ heat stack-list
    +----------...+------------+-----------------+---------------------+--------------+
    | id       ...| stack_name | stack_status    | creation_time       | updated_time |
    +----------...+------------+-----------------+---------------------+--------------+
    | 988ad9c3-...| overcloud  | CREATE_COMPLETE | 2016-03-21T14:32:21 | None         |
    +----------...+------------+-----------------+---------------------+--------------+

And you can source the ``overcloudrc`` file if you want to interact with
the overcloud::

    [stack@undercloud ~]$ . overcloudrc
    [stack@undercloud ~]$ nova service-list
    +----+------------------+-------------------------------------+----------+-...
    | Id | Binary           | Host                                | Zone     | ...
    +----+------------------+-------------------------------------+----------+-...
    | 1  | nova-cert        | overcloud-controller-0              | internal | ...
    | 2  | nova-consoleauth | overcloud-controller-0              | internal | ...
    | 5  | nova-scheduler   | overcloud-controller-0              | internal | ...
    | 6  | nova-conductor   | overcloud-controller-0              | internal | ...
    | 7  | nova-compute     | overcloud-novacompute-0.localdomain | nova     | ...
    +----+------------------+-------------------------------------+----------+-...

Note, when an undercloud node is hosted on an OpenStack cloud instead, the ssh
access user name may be 'centos' or the like. And you may not be able to login
as the root. The UC node name may be also prefixed with a given heat stack name,
like `foo-undercloud`. The node also should be given a floating IP to serve as a
bastion host proxying ansible/ssh to overcloud nodes.

Access via the TripleO-UI
-------------------------

With baremetal and ovb based deployments you can access the TripleO-UI via the
undercloud's public ip address https://<virthost>

Deploying TripleO in a libvirt based environment presents the additional
challenge of accessing the isolated ovs networks on the undercloud. By default
an ssh-tunnel service has been setup on the virthost by the tripleo-quickstart
`enable_port_forward_for_tripleo_ui` variable.  Access the TripleO-UI with the following.

From your workstation::

    https://<virthost>

By default a secure connection to the undercloud services has been configured
in the /var/www/openstack-tripleo-ui-/dist/tripleo_ui_config.js file.  To use
an insucure connections change the default variable
``tripleo_ui_secure_access`` to false.
