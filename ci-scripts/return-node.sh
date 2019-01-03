#!/bin/bash
# Return a CI node

set -eux

VIRTHOST_KEY=$(head -n1 $WORKSPACE/cico_key.txt)
$WORKSPACE/bin/cico node done $VIRTHOST_KEY
$WORKSPACE/bin/cico inventory
