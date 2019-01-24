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
    --requirements requirements.txt \
    --requirements quickstart-extras-requirements.txt \
    --requirements ci-scripts/ci-base-requirements.txt \
    --playbook noop.yml \
    localhost
popd

$WORKSPACE/bin/cico node get \
    --arch x86_64 \
    --release 7 \
    --count 1 \
    --retry-count 6 \
    --retry-interval 60 \
    -f csv | sed "1d" > $WORKSPACE/provisioned.csv

$WORKSPACE/bin/cico inventory
if [ -s $WORKSPACE/provisioned.csv ]; then
    cat $WORKSPACE/provisioned.csv
else
    echo "FATAL: no nodes were provisioned"
    exit 1
fi

export VIRTHOST=`cat provisioned.csv | tail -1 | cut -d "," -f 3| sed -e 's/"//g'`
export VIRTHOST_KEY=`cat provisioned.csv | tail -1 | cut -d "," -f 7| sed -e 's/"//g'`
echo $VIRTHOST > $WORKSPACE/virthost
echo $VIRTHOST_KEY > $WORKSPACE/cico_key.txt
