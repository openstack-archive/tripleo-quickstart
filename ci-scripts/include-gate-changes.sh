# Source this script from within other gating scripts to provide depends-on
# functionality for quickstart and quickstart-extras

: ${OPT_ADDITIONAL_PARAMETERS:=""}

# preparation steps to run with the gated changes
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
    mv $WORKSPACE/tripleo-quickstart $WORKSPACE/tripleo-quickstart-old
    mv $WORKSPACE/tripleo-quickstart-gate-repo $WORKSPACE/tripleo-quickstart
    cp $WORKSPACE/tripleo-quickstart-old/*requirements* $WORKSPACE/tripleo-quickstart/
    # Change into the new quickstart directory to use the new changes
    cd $WORKSPACE/tripleo-quickstart
fi
export VIRTUAL_ENV=$WORKSPACE
export PATH="$VIRTUAL_ENV/bin:$PATH"
pushd $WORKSPACE/tripleo-quickstart
python setup.py install
popd
pushd $WORKSPACE/tripleo-quickstart-extras
python setup.py install
popd