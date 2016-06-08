#!/bin/bash
# Get a CI node

set -eux

pushd $WORKSPACE/tripleo-quickstart
# (trown) Use quickstart.sh to set up the environment.
# This serves as a fail-fast syntax check for quickstart gates.
bash quickstart.sh \
    --working-dir $WORKSPACE/ \
    --no-clone \
    --bootstrap \
    --playbook noop.yml \
    localhost
popd

# (trown) I don't totally understand why this is needed here, but activating
# the venv is failing otherwise.
export VIRTUAL_ENV_DISABLE_PROMPT=1
source $WORKSPACE/bin/activate

pip install python-cicoclient

cico node get --arch x86_64 \
              --release 7 \
              --count 1 \
              --retry-count 2 \
              --retry-interval 30 \
              -f csv > $WORKSPACE/provisioned.csv

cico inventory
cat $WORKSPACE/provisioned.csv

export VIRTHOST=`cat provisioned.csv | tail -1 | cut -d "," -f 3| sed -e 's/"//g'`
export VIRTHOST_KEY=`cat provisioned.csv | tail -1 | cut -d "," -f 7| sed -e 's/"//g'`
echo $VIRTHOST > $WORKSPACE/virthost
echo $VIRTHOST_KEY > $WORKSPACE/cico_key.txt
