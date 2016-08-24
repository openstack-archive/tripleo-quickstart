#!/bin/bash
# Basic CI test that runs quickstart.sh with only the
# release argument
# Usage: basic.sh <release> <build_system> <config> <job_type>
set -eux

# CONFIG and JOB_TYPE are not used here, but kept for
# consistency with other jobs to make JJB cleaner.
RELEASE=$1
BUILD_SYS=$2
CONFIG=$3
JOB_TYPE=$4

bash $WORKSPACE/tripleo-quickstart/quickstart.sh \
    --working-dir $WORKSPACE/ \
    --no-clone \
    --release $RELEASE \
    $VIRTHOST
