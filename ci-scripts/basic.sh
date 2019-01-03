#!/bin/bash
# Basic CI test that runs quickstart.sh with only the
# release argument
# Usage: basic.sh <release> <build_system> <config> <job_type>
set -eux

: ${OPT_ADDITIONAL_PARAMETERS:=""}

# CONFIG and JOB_TYPE are not used here, but kept for
# consistency with other jobs to make JJB cleaner.
RELEASE=$1
# unused variable in script, kept for consistency
BUILD_SYS=$2
CONFIG=$3
JOB_TYPE=$4

# Default to using a user other than "stack" as the virthost user.
# This will flush out code that makes assumptions about
# usernames or working directories.
: ${VIRTHOST_USER:=cistack}

# (trown) This is so that we ensure separate ssh sockets for
# concurrent jobs. Without this, two jobs running in parallel
# would try to use the same undercloud-stack socket.
socketdir=$(mktemp -d /tmp/sockXXXXXX)
export ANSIBLE_SSH_CONTROL_PATH=$socketdir/%%h-%%r

# preparation steps to run with the gated roles
CI_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $CI_SCRIPT_DIR/include-gate-changes.sh

# CI_ENV is set on the slave running the jobs
# REL_TYPE can be specific release type like 'testing'

bash quickstart.sh \
    --playbook quickstart-extras.yml \
    --working-dir $WORKSPACE/ \
    --no-clone \
    --bootstrap \
    -e virthost_user=$VIRTHOST_USER \
    --release ${CI_ENV:+$CI_ENV/}$RELEASE${REL_TYPE:+-$REL_TYPE} \
    $VIRTHOST
