.. _accessing-overcloud:

Accessing the Overcloud
=======================

With the virtual infrastructure provisioned by tripleo-quickstart, the
overcloud hosts are deployed on an isolated network that can only be accessed
from the undercloud host. In many cases, simply logging in to the undercloud
host as documented in :ref:`accessing-undercloud` is sufficient, but there are
situations when you may want direct access to overcloud services from your
desktop.

Note, when overcloud nodes are hosted on an OpenStack cloud instead, the ssh
access user name may be 'centos' or the like. And you may not be able to login
as the root. Node names may be also prefixed with a given heat stack name, like
`foo-overcloud-controller-0`. The undercloud node should be given a floating IP
and will be serving as a bastion host proxying ansible/ssh to overcloud nodes.

Logging in to overcloud hosts
-----------------------------

The easiest way to reach the overcloud nodes is to login using the ssh config
file generated during the quickstart run::

    ssh -F $HOME/.quickstart/ssh.config.ansible overcloud-controller-0

It's a good idea to look into the `ssh.config.ansible` file to see all the
hostnames and to understand how ssh logs in to the overcloud nodes though the
undercloud.

An alternative way to reach the overcloud nodes is to log in to the undercloud
host and figure out the ctlplane address of the deployed node::

    [stack@undercloud ~]$ source stackrc
    [stack@undercloud ~]$ nova list
    +--------------------------------------+-------------------------+--------+------------+-------------+------------------------+
    | ID                                   | Name                    | Status | Task State | Power State | Networks               |
    +--------------------------------------+-------------------------+--------+------------+-------------+------------------------+
    | 3d4a79d1-53ea-4f32-b496-fbdcbbb6a5a3 | overcloud-controller-0  | ACTIVE | -          | Running     | ctlplane=192.168.24.16 |
    | 4f8acb6d-6394-4193-a6c6-50d8731fad7d | overcloud-novacompute-0 | ACTIVE | -          | Running     | ctlplane=192.168.24.8  |
    +--------------------------------------+-------------------------+--------+------------+-------------+------------------------+

The address is randomly assigned and depends on the deployment environment. In
this case the compute node has the address `192.168.24.8`. Logging in to any of
the nodes is possible with the `heat-admin` user. This user has full sudo
rights on all the overcloud nodes and the undercloud is set up to login with
public key authentication::

    ssh heat-admin@192.168.24.8

The node can be also accessed by a static hostname of
`overcloud-novacompute-0.ctlplane` in newer versions of OpenStack.

SSH Port Forwarding
-------------------

You can forward specific ports from your localhost to addresses on the
overcloud network. For example, to access the overcloud Horizon
interface, you could run::

    ssh -F $HOME/.quickstart/ssh.config.ansible \
      -L 8080:overcloud.localdomain:80 undercloud

This uses the ssh ``-L`` command line option to forward port ``8080`` on
your local host to port ``80`` on the ``overcloud.localdomain`` host
(which is defined in ``/etc/hosts`` on the undercloud). Once you have
connected to the undercloud like this, you can then point your browser
at ``http://localhost:8080`` to access Horizon.

You can add multiple ``-L`` arguments to the ssh command line to expose
multiple services.


SSH Dynamic Proxy
-----------------

You can configure ssh as a
`SOCKS5 <https://www.ietf.org/rfc/rfc1928.txt>`__ proxy with the ``-D``
command line option. For example, to start a proxy on port 1080::

    ssh -F $HOME/.quickstart/ssh.config.ansible \
      -D 1080 undercloud

You can now use this proxy to access any overcloud resources. With curl,
that would look something like this::

    $ curl --socks5-hostname localhost:1080 http://overcloud.localdomain:5000/
    {"versions": {"values": [{"status": "stable", "updated": "2016-04-04T00:00:00Z",...

Access to the overclouds horizon web interface
----------------------------------------------

With baremetal and ovb based deployments you can access horizon via the
overclouds's controller public ip address http://<controller_ip>:80

Deploying TripleO in a libvirt based environment presents an additional
challenge of access the isolated ovs networks on the undercloud. By default
an ssh-tunnel service has been setup on the virthost with the tripleo-quickstart
for libvirt deployments.  Access horizon with the following.

From the localhost::

    http://<virthost>:8181

Overcloud with SSL enabled

    http://<virthost>:8443



Using Firefox
^^^^^^^^^^^^^

You can configure Firefox to use a SOCKS5 proxy. You may want to create
`create a new
profile <https://support.mozilla.org/en-US/kb/profile-manager-create-and-remove-firefox-profiles>`__
for this so that you don't impact your normal browsing.

#. Select Edit -> Preferences
#. Select the "Advanced" tab from the list on the left of the window
#. Select the "Network" tab from the list across the top of the window
#. Select the "Settings..." button in the "Connection" section
#. Select "Manual proxy configuration:" in the "Connection Settings"
   dialog.
#. Enter ``localhost`` in the "SOCKS Host" field, and enter ``1080`` (or
   whatever port you supplied to the ssh ``-D`` option) in the "Port:"
   field.
#. Select the "SOCKS5" radio button, and check the "Remote DNS"
   checkbox.

Now, if you enter http://overcloud.localdomain/ in your browser, you will
be able to access the overcloud Horizon instance. Note that you will
probably need to enter the full URL; entering an unqualified hostname
into the location bar will redirect to a search engine rather than
attempting to contact the website.

Using Chrome
^^^^^^^^^^^^

It is not possible to configure a proxy connection using the Chrome UI
without using an extension. You can set things up from the command line
by using `these
instructions <https://www.chromium.org/developers/design-documents/network-stack/socks-proxy>`__,
which boil down to starting Chrome like this::

    google-chrome --proxy-server="socks5://localhost:1080" \
      --host-resolver-rules="MAP * 0.0.0.0"

sshuttle
--------

The `sshuttle <https://github.com/apenwarr/sshuttle>`__ tool is
something halfway between a VPN and a proxy server, and can be used to
give your local host direct access to the overcloud network.

#. Note the network range used by the overcloud servers; this will be
   the value of ``undercloud_network`` in your configuration, which as
   of this writing defaults for historical reasons to ``192.0.2.0/24``.

#. Install the ``sshuttle`` package if you don't already have it

#. Run ``sshuttle``::

       sshuttle \
         -e "ssh -F $HOME/.quickstart/ssh.config.ansible" \
         -r undercloud -v 192.0.2.0/24

   (Where ``192.0.2.0/24`` should be replaced by whatever address range
   you noted in the first step.)

With this in place, your local host can access any address on the
overcloud network. Hostname resolution *will not work*, but since the
generated credentials files use ip addresses this should not present a
problem.

CLI access with tsocks
----------------------

If you want to use command line tools like the ``openstack`` integrated
client to access overcloud API services, you can use
`tsocks <http://tsocks.sourceforge.net/>`__, which uses function
interposition to redirect all network access to a SOCKS proxy.

#. Install the ``tsocks`` package if you don't already have it
   available.
#. Create a ``$HOME/.tsocks`` configuration file with the following
   content::

       server = 127.0.0.1
       server_port = 1080

#. Set the ``TSOCKS_CONF_FILE`` environment variable to point to this
   configuration file::

       export TSOCKS_CONF_FILE=$HOME/.tsocks

#. Use the ``tsocks`` command to wrap your command invocations::

       $ tsocks openstack flavor list
       +----+-----------+-------+------+-----------+-------+-----------+
       | ID | Name      |   RAM | Disk | Ephemeral | VCPUs | Is Public |
       +----+-----------+-------+------+-----------+-------+-----------+
       | 1  | m1.tiny   |   512 |    1 |         0 |     1 | True      |
       | 2  | m1.small  |  2048 |   20 |         0 |     1 | True      |
       | 3  | m1.medium |  4096 |   40 |         0 |     2 | True      |
       | 4  | m1.large  |  8192 |   80 |         0 |     4 | True      |
       | 5  | m1.xlarge | 16384 |  160 |         0 |     8 | True      |
       +----+-----------+-------+------+-----------+-------+-----------+

This solution is known to work with the ``openstack`` integrated client,
and known to *fail* with many of the legacy clients (such as the
``nova`` or ``keystone`` commands).
