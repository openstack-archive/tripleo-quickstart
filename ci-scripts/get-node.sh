#!/bin/bash
# Get a CI node

set -eux

pushd $WORKSPACE/tripleo-quickstart
# (trown) Use quickstart.sh to set up the environment.
# This serves as a fail-fast syntax check for quickstart gates.
./quickstart.sh \
    --working-dir $WORKSPACE/ \
    --no-clone \
    --bootstrap \
    --requirements ci-scripts/ci-base-requirements.txt \
    --playbook noop.yml \
    localhost
popd

$WORKSPACE/bin/cico node get --arch x86_64 \
              --release 7 \
              --count 1 \
              --retry-count 2 \
              --retry-interval 30 \
              -f csv > $WORKSPACE/provisioned.csv

$WORKSPACE/bin/cico inventory
cat $WORKSPACE/provisioned.csv

export VIRTHOST=`cat provisioned.csv | tail -1 | cut -d "," -f 3| sed -e 's/"//g'`
export VIRTHOST_KEY=`cat provisioned.csv | tail -1 | cut -d "," -f 7| sed -e 's/"//g'`
echo $VIRTHOST > $WORKSPACE/virthost
echo $VIRTHOST_KEY > $WORKSPACE/cico_key.txt
