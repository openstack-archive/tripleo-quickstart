#!/bin/bash
# Full CI test that runs quickstart.sh with only the
# release argument

set -eux

bash $WORKSPACE/tripleo-quickstart/quickstart.sh \
--tags all \
--config $WORKSPACE/tripleo-quickstart/config/general_config/minimal.yml \
--working-dir $WORKSPACE/ \
--no-clone \
$VIRTHOST $RELEASE
