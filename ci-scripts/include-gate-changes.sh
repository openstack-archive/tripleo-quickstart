#!/bin/bash
# CI script that includes gate changes and dependencies to be run in jobs.
# This script should be run before a quickstart.sh run testing the change.
# Usage: include-gate-change.sh <release> <job_type> <virthost>

# preparation steps to run with the gated roles
if [ "$JOB_TYPE" = "gate" ] || [ "$JOB_TYPE" = "dlrn-gate-check" ]; then
    bash quickstart.sh \
        --working-dir $WORKSPACE/ \
        --no-clone \
        --bootstrap \
        --playbook gate-quickstart.yml \
        --release ${CI_ENV:+$CI_ENV/}$RELEASE${REL_TYPE:+-$REL_TYPE} \
        $OPT_ADDITIONAL_PARAMETERS \
        $VIRTHOST
fi

# Rename tripleo-quickstart directory to include the gated change
if [ -d $WORKSPACE/tripleo-quickstart-gate-repo ]; then
    mv $WORKSPACE/tripleo-quickstart $WORKSPACE/tripleo-quickstart-old;
    mv $WORKSPACE/tripleo-quickstart-gate-repo $WORKSPACE/tripleo-quickstart;
    cp $WORKSPACE/tripleo-quickstart-old/requirements* $WORKSPACE/tripleo-quickstart/;
fi


