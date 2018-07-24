Running the quickstart as an unprivileged user
==============================================

It is possible to run the bulk of the quickstart deployment as an
unprivileged user (a user without root access). In order to do this,
there are a few system configuration tasks that must be performed in
advance:

-  Making sure required packages are installed
-  Configuring the required libvirt networks

Automatic system configuration
------------------------------

If you want to perform the system configuration tasks manually, skip
this section and start reading below at "Configure KVM".

Place the following into ``playbook.yml`` in the ``tripleo-quickstart``
directory::

    - hosts: localhost
      roles:
        - environment/setup

And run it like this (assuming that you have ``sudo`` access on your
local host)::

    ansible-playbook playbook.yml

Continue reading at `Deploying Tripleo <#deploying-tripleo>`__.

Configure KVM
-------------

You will need to ensure that the ``kvm`` kernel module is loaded, and
that the appropriate process-specific module (``kvm_intel`` or
``kvm_amd``) is loaded. Run the appropriate ``modprobe`` command to load
the module::

    # modprobe kvm_intel [options...]

Or::

    # modprobe kvm_amd [options...]

Where ``[options...]`` in the above is either empty, or ``nested=1`` if
you want to enable `nested
kvm <https://www.kernel.org/doc/Documentation/virtual/kvm/nested-vmx.txt>`__.

To ensure this module will be loaded next time your system boots, create
``/etc/modules-load.d/oooq_kvm.conf`` with the following content on
Intel systems::

    kvm_intel

Or on AMD systems::

    kvm_amd

If you want to enable `nested
kvm <https://www.kernel.org/doc/Documentation/virtual/kvm/nested-vmx.txt>`__
persistently, create the file ``/etc/modprobe.d/kvm.conf`` with the
following contents::

    options kvm_intel nested=1
    options kvm_amd nested=1

Required packages
-----------------

You will need to install the following packages:

-  ``qemu-kvm``
-  ``libvirt``
-  ``libvirt-python``
-  ``libguestfs-tools``
-  ``python-lxml``

Once these packages are installed, you need to start ``libvirtd``
::

    # systemctl enable libvirtd
    # systemctl start libvirtd

Configuring libvirt networks
----------------------------

Quickstart requires two networks. The ``external`` network provides
inbound access into the virtual environment set up by the playbooks. The
``overcloud`` network connects the overcloud hosts to the undercloud,
and is used both for provisioning, inbound access to the overcloud, and
communication between overcloud hosts.

In the following steps, note that the names you choose for the libvirt
networks are unimportant (because the vms will be wired up to these
networks using bridge names, rather than libvirt network names).

The external network
^^^^^^^^^^^^^^^^^^^^

If you have the standard ``default`` libvirt network, you can just use
that as your ``external`` network. If you would prefer to create a new
one, run something like the following::

    # virsh net-define /dev/stdin <<EOF
    <network>
      <name>external</name>
      <forward mode='nat'>
        <nat>
          <port start='1024' end='65535'/>
        </nat>
      </forward>
      <bridge name='brext' stp='on' delay='0'/>
      <ip address='192.168.23.1' netmask='255.255.255.0'>
        <dhcp>
          <range start='192.168.23.2' end='192.168.23.254'/>
        </dhcp>
      </ip>
    </network>
    EOF
    # virsh net-start external
    # virsh net-autostart external

The overcloud network
^^^^^^^^^^^^^^^^^^^^^

The overcloud network is really just a bridge, so you could simply
configure this through your distributions standard mechanism for
configuring persistent bridge devices. You can also do it via libvirt
like this::

    # virsh net-define /dev/stdin <<EOF
    <network>
      <name>overcloud</name>
      <bridge name="brovc" stp='off' delay='0'/>
    </network>
    EOF
    # virsh net-start overcloud
    # virsh net-autostart overcloud

Whitelisting bridges
^^^^^^^^^^^^^^^^^^^^

Once you have started the libvirt networks, you need to enter the bridge
names in the ``/etc/qemu/bridge.conf`` file, which makes these bridges
available to unprivileged users via the `qemu bridge
helper <http://wiki.qemu.org/Features-Done/HelperNetworking>`__. Note
that on some systems this file will be called
``/etc/qemu-kvm/bridge.conf``.

Add an ``allow`` line for each bridge you created in the previous steps::

    allow brext
    allow brovc

Deploying TripleO
-----------------

With all of the system configuration tasks out of the way, the rest of
the process can be run as an unprivileged user. You will need to create
a YAML document that describes your network configuration and that
optionally changes any of the default values used in the quickstart
deployment. To describe the network resources we created above, I would
create a file called ``config.yml`` with the following content::

    networks:
      - name: external
        bridge: brext
        address: 192.168.23.1
        netmask: 255.255.255.0

      - name: overcloud
        bridge: brovc

You must have one network named ``external`` and one network named
``overcloud``. The ``address`` and ``netmask`` values must match the
values you used to create the libvirt networks.

Place the following into a file ``playbook.yml`` in your
``tripleo-quickstart`` directory::

    - hosts: localhosts
      roles:
        - libvirt/setup
        - tripleo/undercloud
        - tripleo/overcloud

And run it like this::

    ansible-playbook playbook.yml -e @config.yml

This will deploy the default virtual infrastructure, which includes an
undercloud node, three controllers, one compute node, and one ceph node,
and which requires at least 32GB of memory. If you want to deploy a
smaller environment, you could use the ``minimal.yml`` settings we use
in our CI environment::

    ansible-playbook playbook.yml -e @config.yml \
      -e playbooks/centosci/minimal.yml

This will create a virtual environment with a single controller and a
single compute node, with a total memory footprint of around 22GB.

See :ref:`configuration` for more information.
