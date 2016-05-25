#!/bin/bash
# Return a CI node

set -eux

# (trown) I don't totally understand why this is needed here, but activating
# the venv is failing otherwise.
export VIRTUAL_ENV_DISABLE_PROMPT=1
source $WORKSPACE/bin/activate

VIRTHOST_KEY=$(head -n1 $WORKSPACE/cico_key.txt)
cico node done $VIRTHOST_KEY
cico inventory
