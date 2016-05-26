#!/usr/bin/python
# coding: utf-8 -*-

# generate_baremetal_macs method ripped from
# openstack/tripleo-incubator/scripts/configure-vm

DOCUMENTATION = '''
---
module: generate_macs
version_added: "2.0"
short_description: Generate a list of Ethernet MAC addresses
description:
   - Generate a list of Ethernet MAC addresses suitable for baremetal testing.
'''

import math
import random

MAX_NUM_MACS = math.trunc(0xff/2)


def generate_baremetal_macs(nodes, networks):
    """Generate an Ethernet MAC address suitable for baremetal testing."""
    # NOTE(dprince): We generate our own bare metal MAC address's here
    # instead of relying on libvirt so that we can ensure the
    # locally administered bit is set low. (The libvirt default is
    # to set the 2nd MSB high.) This effectively allows our
    # fake baremetal VMs to more accurately behave like real hardware
    # and fixes issues with bridge/DHCP configurations which rely
    # on the fact that bridges assume the MAC address of the lowest
    # attached NIC.
    # MACs generated for a given machine will also be in sequential
    # order, which matches how most BM machines are laid out as well.
    # Additionally we increment each MAC by two places.
    macs = []
    count = len(nodes) * len(networks)

    if count > MAX_NUM_MACS:
        raise ValueError("The MAX num of MACS supported is %i  "
                         "(you specified %i)." % (MAX_NUM_MACS, count))

    base_nums = [0x00,
                 random.randint(0x00, 0xff),
                 random.randint(0x00, 0xff),
                 random.randint(0x00, 0xff),
                 random.randint(0x00, 0xff)]
    base_mac = ':'.join(map(lambda x: "%02x" % x, base_nums))

    start = random.randint(0x00, 0xff)
    if (start + (count * 2)) > 0xff:
        # leave room to generate macs in sequence
        start = 0xff - count * 2
    for num in range(0, count*2, 2):
        mac = start + num
        macs.append(base_mac + ":" + ("%02x" % mac))

    result = {}
    for node in nodes:
        result[node['name']] = {}
        for network in networks:
            result[node['name']][network['name']] = macs.pop(0)

    return result


def main():
    module = AnsibleModule(
        argument_spec=dict(
            nodes=dict(required=True, type='list'),
            networks=dict(required=True, type='list')
        )
    )
    result = generate_baremetal_macs(module.params["nodes"],
                                     module.params["networks"])
    module.exit_json(**result)

# see http://docs.ansible.com/developing_modules.html#common-module-boilerplate
from ansible.module_utils.basic import *
main()
