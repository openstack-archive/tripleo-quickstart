#!/bin/bash
# Basic CI test that runs quickstart.sh with only the
# release argument

set -eux

bash $WORKSPACE/tripleo-quickstart/quickstart.sh \
    --working-dir $WORKSPACE/ \
    --no-clone \
    $VIRTHOST $RELEASE