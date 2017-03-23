#!/bin/bash
# Basic CI test that runs quickstart.sh with only the
# release argument
# Usage: basic.sh <release> <build_system> <config> <job_type>
set -eux

# CONFIG and JOB_TYPE are not used here, but kept for
# consistency with other jobs to make JJB cleaner.
RELEASE=$1
# unused variable in script, kept for consistency
BUILD_SYS=$2
CONFIG=$3
JOB_TYPE=$4

# (trown) This is so that we ensure separate ssh sockets for
# concurrent jobs. Without this, two jobs running in parallel
# would try to use the same undercloud-stack socket.
socketdir=$(mktemp -d /tmp/sockXXXXXX)
export ANSIBLE_SSH_CONTROL_PATH=$socketdir/%%h-%%r

# CI_ENV is set on the slave running the jobs
# REL_TYPE can be specific release type like 'testing'

bash quickstart.sh \
    --working-dir $WORKSPACE/ \
    --no-clone \
    --release ${CI_ENV:+$CI_ENV/}$RELEASE${REL_TYPE:+-$REL_TYPE} \
    $VIRTHOST

