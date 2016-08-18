.. _accessing-undercloud:

Accessing the Undercloud
========================

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
