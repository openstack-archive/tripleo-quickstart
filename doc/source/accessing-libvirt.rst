Accessing libvirt as an unprivileged user
=========================================

The virtual infrastructure provisioned by triple-quickstart is created
using an unprivileged account (by default the ``stack`` user). This
means that logging into your virthost as root and running ``virsh list``
will result in empty output, which can be confusing to someone not
familiar with libvirt's unprivileged mode.

Where are my guests?
--------------------

The easiest way to interact with the unprivileged libvirt instance used
by tripleo-quickstart is to log in as the ``stack`` user using the
generated ssh key in your quickstart directory::

    $ ssh -i $HOME/.quickstart/id_rsa_virt_host stack@virthost
    [stack@virthost ~]$ virsh list
     Id    Name                           State
    ----------------------------------------------------
     2     undercloud                     running
     5     compute_0                      running
     6     control_0                      running

You can also log in to the virthost as ``root`` and then ``su - stack``
to access the unprivileged user account. While this won't normally work
"out of the box" because of `this
issue <https://www.redhat.com/archives/libvirt-users/2016-March/msg00056.html>`__,
the quickstart ensures that the ``XDG_RUNTIME_DIR`` variable is set
correctly.

To console into the guests you'll have to add -c qemu:///session.
For example::

    $ virsh -c qemu:///session console undercloud

To set the password for the undercloud and overcloud root user you can set
the `overcloud_full_root_pwd` variable.

    quickstart.sh <snip> -e overcloud_full_root_pwd=password <snip> virthost

Where are my networks?
----------------------

While most libvirt operations can be performed as an unprivileged user,
creating bridge devices requires root privileges. We create the networks
used by the quickstart as ``root``, so as ``root`` on your virthost you
can run::

    # virsh net-list

And see::

     Name                 State      Autostart     Persistent
     --------------------------------------------------------
     default              active     yes           yes
     external             active     yes           yes
     overcloud            active     yes           yes

In order to expose these networks to the unprivileged ``stack`` user, we
whitelist them in ``/etc/qemu/bridge.conf`` (this file is used by the
`qemu bridge
helper <http://wiki.qemu.org/Features-Done/HelperNetworking>`__ to proxy
unprivileged access to privileged operations)::

    # cat /etc/qemu-kvm/bridge.conf
    allow virbr0
    allow brext
    allow brovc

The guests created by the stack user connect to these bridges by name;
the relevant domain XML ends up looking something like::

    [stack@virthost ~]$ virsh dumpxml undercloud | xmllint --xpath //interface -
    <interface type="bridge">
      <mac address="00:12:b3:cf:2d:cb"/>
      <source bridge="brext"/>
      <target dev="tap0"/>
      <model type="virtio"/>
      <alias name="net0"/>
    </interface>
    <interface type="bridge">
      <mac address="00:12:b3:cf:2d:cd"/>
      <source bridge="brovc"/>
      <target dev="tap1"/>
      <model type="virtio"/>
      <alias name="net1"/>
    </interface>

What if I want privileged mode instead?
---------------------------------------

Unprivileged mode is sometimes inconvenient, for example as a developer
working as a single user on local hardware, it may be preferable
to use privileged mode so that quickstart VMs can survive a host reboot
and also so that it's easier to access host tools such as virt-manager
(which is particularly useful for diagnosing boot issues via the primary
console).

To enable this mode you can select the following environment::

  quickstart.sh -E config/environments/dev_privileged_libvirt.yml $VIRTHOST
