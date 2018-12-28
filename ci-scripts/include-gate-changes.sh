# Source this script from within other gating scripts to provide depends-on
# functionality for quickstart and quickstart-extras

: ${OPT_ADDITIONAL_PARAMETERS:=""}

# preparation steps to run with the gated changes
if [ "$JOB_TYPE" = "gate" ] || \
    [ "$JOB_TYPE" = "dlrn-gate-check" ] || \
    [ "$JOB_TYPE" = "standalone" ]; then

    pushd $WORKSPACE/tripleo-quickstart
    sed -i.bak '/extras/d' $WORKSPACE/tripleo-quickstart/quickstart-extras-requirements.txt
    echo "file://$WORKSPACE/tripleo-quickstart-extras/#egg=tripleo-quickstart-extras" >> $WORKSPACE/tripleo-quickstart/quickstart-extras-requirements.txt
    popd

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
