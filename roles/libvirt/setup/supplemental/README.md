libvirt/setup/supplemental
==========================

An Ansible role for provisioning a supplemental node prior to deployment
of the TripleO undecloud

Requirements
------------

This role pairs with the libvirt/setup role to provision a supplemental node
VM.

The role expects to be provided with a `supplemental_provision_script` which
will be copied to the virthost during execution and is responsible for
preparing the the vm's image and adding it to the proper libvirt pool.
Furthermore, the `supplemental_node_ip` must be configured by this script and
it will be used to add the host to ansible in-memory inventory as well as
in preparation of ssh config files by the tripleo-inventory role.

**Note:** If `enable_tls_everywhere` is true, this role will provision the
supplemental node for deployment of a FreeIPA server using the
`tls_everywhere_provisioner.sh` script in lieu of the  `supplemental_provision_script`.

Role Variables
--------------

supplemental_node_key: "{{ local_working_dir }}/id_rsa_supplemental"
supplemental_base_image_url: https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2

* `deploy_supplemental_node` -- <false> if true, provision supplemental node
* `supplemental_node_key` -- Location of key to be used for access to
  supplemental node vm.
* `supplemental_base_image_url` -- URL of base image to be provisioned against
* `supplemental_node_ip` -- IP which provisioned node will be externally accessible from
* `supplemental_provisioning_script` -- Path to script which will be copied to and run from the
  virthost to provision the vm image
* `supplemental_user` -- <stack> The user which is used to deploy the supplemental node
* `supplemental_tls_everywhere_dns_server` -- <192.168.23.1> DNS server for eth0 on the supplemental
  node hosting the FreeIPA server

Example Playbook
----------------

```yaml
---
- name: Setup supplemental vms
  hosts: virhost
  roles:
    - libvirt/setup/supplemental
```

License
-------

Apache 2.0

Author Information
------------------

RDO-CI Team
