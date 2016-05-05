# Configure libvirt environment

The `environment/setup` role will:

- Install libvirt and any dependencies
- Configure and load the `kvm` module (and arch-specific `kvm_intel`
  or `kvm_amd` module)
- Configure the libvirt networks defined in the `networks` variable
- Whitelist the libvirt network bridges in `/etc/qemu/bridge.conf` (or
  equivalent file)

The `environment/teardown` role will:

- Remove whitelist entries from `/etc/qemu/bridge.conf`
- Destroy and undefine the libvirt networks

The `cleanup` role *will not* remote packages or attempt to undo the
KVM configuration, because these things may have been configured
prior to running the script and we do not want to break an existing
environment.
