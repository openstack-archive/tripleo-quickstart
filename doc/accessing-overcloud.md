# Accessing the Overcloud
 
With the virtual infrastructure provisioned by tripleo-quickstart, the
overcloud hosts are deployed on an isolated network that can only be
accessed from the undercloud host.  In many cases, simply logging in
to the undercloud host as documented in [Accessing the Undercloud][]
is sufficient, but there are situations when you may want direct
access to overcloud services from your desktop.

[accessing the undercloud]: accessing-undercloud.md

## Logging in to overcloud hosts

If you need to log in to an overcloud host directly, first log in to
the `undercloud` host.  From there, you can access the overcloud hosts
by name:

    [stack@undercloud ~]$ ssh overcloud-controller-0
    Warning: Permanently added 'overcloud-controller-0,192.168.30.9' (ECDSA) to the list of known hosts.
    Last login: Wed Mar 23 21:59:24 2016 from 192.168.30.1
    [heat-admin@overcloud-controller-0 ~]$

## SSH Port Forwarding

You can forward specific ports from your localhost to addresses on the
overcloud network.  For example, to access the overcloud Horizon
interface, you could run:

    ssh -F $HOME/.quickstart/ssh.config.ansible \
      -L 8080:overcloud-public-vip:80 undercloud

This uses the ssh `-L` command line option to forward port `8080` on
your local host to port `80` on the `overcloud-public-vip` host (which
is defined in `/etc/hosts` on the undercloud).  Once you have
connected to the undercloud like this, you can then point your browser
at `http://localhost:8080` to access Horizon.

You can add multiple `-L` arguments to the ssh command line to expose
multiple services.

## SSH Dynamic Proxy

You can configure ssh as a [SOCKS5][] proxy with the `-D` command line
option.  For example, to start a proxy on port 1080:

[socks5]: https://www.ietf.org/rfc/rfc1928.txt

    ssh -F $HOME/.quickstart/ssh.config.ansible \
      -D 1080 undercloud

You can now use this proxy to access any overcloud resources.  With
curl, that would look something like this:

    $ curl --socks5-hostname localhost:1080 http://overcloud-public-vip:5000/
    {"versions": {"values": [{"status": "stable", "updated": "2016-04-04T00:00:00Z",...

### Using Firefox

You can configure Firefox to use a SOCKS5 proxy.  You may want to
create [create a new profile][] for this so that you don't impact your
normal browsing.

[create a new profile]: https://support.mozilla.org/en-US/kb/profile-manager-create-and-remove-firefox-profiles

1. Select Edit -> Preferences
1. Select the "Advanced" tab from the list on the left of the window
1. Select the "Network" tab from the list across the top of the window
1. Select the "Settings..." button in the "Connection" section
1. Select "Manual proxy configuration:" in the "Connection Settings"
   dialog.
1. Enter `localhost` in the "SOCKS Host" field, and enter `1080` (or
   whatever port you supplied to the ssh `-D` option) in the "Port:"
   field.
1. Select the "SOCKS5" radio button, and check the "Remote DNS"
   checkbox.

Now, if you enter <http://overcloud-public-vip/> in your browser, you
will be able to access the overcloud Horizon instance.  Note that you
will probably need to enter the full URL; entering an unqualified
hostname into the location bar will redirect to a search engine rather
than attempting to contact the website.

### Using Chrome

It is not possible to configure a proxy connection using the Chrome UI
without using an extension.  You can set things up from the command
line by using [these instructions], which boil down to starting Chrome
like this:

[these instructions]: https://www.chromium.org/developers/design-documents/network-stack/socks-proxy

    google-chrome --proxy-server="socks5://localhost:1080" \
      --host-resolver-rules="MAP * 0.0.0.0"

## sshuttle

The [sshuttle][] tool is something halfway between a VPN and a proxy
server, and can be used to give your local host direct access to the
overcloud network.

[sshuttle]: https://github.com/apenwarr/sshuttle

1. Note the network range used by the overcloud servers; this will be
   the value of `undercloud_network` in your configuration, which as
   of this writing defaults for historical reasons to `192.0.2.0/24`.

1. Install the `sshuttle` package if you don't already have it

1. Run `sshuttle`:

        sshuttle \
          -e "ssh -F $HOME/.quickstart/ssh.config.ansible" \
          -r undercloud -v 192.0.2.0/24

    (Where `192.0.2.0/24` should be replaced by whatever address range
    you noted in the first step.)

With this in place, your local host can access any address on the
overcloud network.  Hostname resolution *will not work*, but since the
generated credentials files use ip addresses this should not present a
problem.

## CLI access with tsocks

If you want to use command line tools like the `openstack` integrated
client to access overcloud API services, you can use [tsocks][], which
uses function interposition to redirect all network access to a SOCKS
proxy.

[tsocks]: http://tsocks.sourceforge.net/

1. Install the `tsocks` package if you don't already have it
   available.
1. Create a `$HOME/.tsocks` configuration file with the following
   content:

        server = 127.0.0.1
        server_port = 1080

1. Set the `TSOCKS_CONF_FILE` environment variable to point to this
   configuration file:

        export TSOCKS_CONF_FILE=$HOME/.tsocks

1. Use the `tsocks` command to wrap your command invocations:

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

This solution is known to work with the `openstack` integrated client,
and known to *fail* with many of the legacy clients (such as the
`nova` or `keystone` commands).
