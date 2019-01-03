#!/bin/bash
# Used to gate ansible-role-tripleo-* repositories
# Usage: gate-roles.sh <release> <build_system> <config> <job_type>

# Note: this script assumes that $WORKSPACE is set prior to calling.

set -eux

source $WORKSPACE/tripleo-environments/ci-scripts/internal-functions.sh

: ${OPT_ADDITIONAL_PARAMETERS:=""}
: ${OPT_SELINUX_PERMISSIVE_UC_INSTALL:="true"}
: ${OPT_INSTALL_UNDERCLOUD_ONLY:="false"}

# JOB_TYPE is not used here, but kept for consistency with other jobs to make JJB cleaner.

RELEASE=$1     # promote: {build-version} (rhos-8, rhos-9, rhos-10, master)
BUILD_SYS=$2   # promote: poodle, puddle (note: unused parameter)
CONFIG=$3      # promote: minimal, pacemaker,
TOPOLOGY=$4    # promote: 3ctlr_1comp_64gb, 3ctlr_1comp_192gb, etc
JOB_TYPE=$5    # promote: promote
PLATFORM=$6    # promote: rhel

# promote: $5 is used to construct the URL we are testing
if [ "$#" -eq 7 ]; then
    export OPT_BUILD_ID=$7
else
    export OPT_BUILD_ID="latest"  # optional
fi

cat << EOF > $WORKSPACE/internal-deploy-vars.txt
Workspace : $WORKSPACE
Release   : $RELEASE
Build_sys : $BUILD_SYS
Config    : $CONFIG
Topology  : $TOPOLOGY
Job Type  : $JOB_TYPE
Platform  : $PLATFORM
Build ID  : $OPT_BUILD_ID
EOF

# note: presently LOCATION isn't used for anything here (yet)
if [ "$JOB_TYPE" = "gate" ] || [ "$JOB_TYPE" = "periodic" ]; then
    LOCATION='stable'
elif [ "$JOB_TYPE" = "promote" ]; then
    LOCATION='testing'
else
    echo "Job type must be one of gate, periodic, or promote"
    exit 1
fi

# (trown) This is so that we ensure separate ssh sockets for
# concurrent jobs. Without this, two jobs running in parallel
# would try to use the same undercloud-stack socket.
socketdir=$(mktemp -d /tmp/sockXXXXXX)
export ANSIBLE_SSH_CONTROL_PATH=$socketdir/%%h-%%r

# TODO / NOTE: this is not used at all internally and should be nuked.  It is merely a place to drift
if [ "$JOB_TYPE" = "gate" ]; then
    # set up the gated repos and modify the requirements file to use them
    bash $WORKSPACE/tripleo-quickstart/quickstart.sh \
        --working-dir $WORKSPACE/ \
        --no-clone \
        --bootstrap \
        --environment $WORKSPACE/config/environments/oooq-internal.yml \
        --playbook gate-roles.yml \
        --release $RELEASE \
        $OPT_ADDITIONAL_PARAMETERS \
        $VIRTHOST

    # once more to let the gating role be gated as well
    bash $WORKSPACE/tripleo-quickstart/quickstart.sh \
        --working-dir $WORKSPACE/ \
        --no-clone \
        --bootstrap \
        --environment $WORKSPACE/config/environments/oooq-internal.yml \
        --playbook gate-roles.yml \
        --release $RELEASE \
        $OPT_ADDITIONAL_PARAMETERS \
        $VIRTHOST
fi

# note: if job type is promote, we're specifying the image URL via an explicit link.  If not, use --release instead
# note: undercloud_image_url takes precedence over the same thing defined in config/release/$RELEASE.yml
if [ "$JOB_TYPE" = "promote" ]; then

    # for RDO on RHEL jobs, BUILD_ID ends up being a full url to a delorean repo.  For internal OSP (rhos-n), it's just a build tag
    # this is because the OSP jobs use rhos-release (which wants a date tag), and for RDO on RHEL builds, we need the actual URL.
    if [[ $RELEASE = "master" || $RELEASE = "queens" || $RELEASE = "pike" || $RELEASE = "ocata" || $RELEASE = "newton" ]]; then
        # ex: http://trunk.rdoproject.org/centos7/5b/b1/5bb13005806597e38ee504bf5a3f42b437ec0890_af9bddfb
        #                                                               ^----- $7
        OPT_DELOREAN_URI=$OPT_BUILD_ID
        OPT_BUILD_ID=$(get_delorean_hash_from_url $OPT_DELOREAN_URI)
    fi

    touch $WORKSPACE/build-id.$OPT_BUILD_ID

    # map $CONFIG (aka {functional_config} in JJB) to an actual yml
    FEATURESET=$(get_featureset_from_functional_config $CONFIG)

    # this is a temporary fix to unstick RDO on RHEL: master for OSP 10 beta import
    # we can't park this in --release loaded config file for reasons.  using image config location instead
    # https://trello.com/c/gdKD9x1K/197-rdo-on-rhel-master-make-undercloud-selinux-permissive-post-uc-install
    #
    # OPT_SELINUX_PERMISSIVE_UC_INSTALL --> not "true" will disable

    # TODO: Fix quickstart.sh - has a latent bug, init to =() is not enough)
    OPT_VARS+=("")

    if [ "$OPT_SELINUX_PERMISSIVE_UC_INSTALL" = "true" ]; then
        if [[ $RELEASE = "master" || $RELEASE = "queens" || $RELEASE = "pike" || $RELEASE = "ocata" || $RELEASE = "newton" ]]; then
            OPT_VARS+=("-e")
            OPT_VARS+=("undercloud_install_script=$WORKSPACE/image-build/$RELEASE/latest/undercloud-install-selinux-permissive.sh.j2")
        fi
    fi

    if [[ $RELEASE = "rhos-12" || $RELEASE = "rhos-13" ]]; then
        export FEATURESET=featureset022

        # TODO: remove when/if https://review.openstack.org/#/c/529408 lands
        OPT_VARS+=("-e tempest_config=true")
        OPT_VARS+=("-e run_tempest=true")
        OPT_VARS+=("-e tempest_workers=4")
        OPT_VARS+=("-e test_white_regex=smoke|test_minimum_basic|test_network_basic_ops|test_snapshot_pattern|test_volume_boot_pattern")
    fi

    # This passes the correct tq release config file for rdo on rhel
    if [[ $RELEASE = "master" || $RELEASE = "queens" || $RELEASE = "pike" || $RELEASE = "ocata" || $RELEASE = "newton" ]]; then
        if [[ $PLATFORM = "rhel" ]]; then
            RELEASE=$RELEASE-rhel
        fi
    fi

    if [ "$OPT_INSTALL_UNDERCLOUD_ONLY" = "true" ]; then
        # if we don't provide --tags it picks up oooq default (UC only)
        # https://github.com/openstack/tripleo-quickstart/blob/master/quickstart.sh#L8
        # DEFAULT_OPT_TAGS="untagged,provision,environment,undercloud-scripts,overcloud-scripts,undercloud-install,undercloud-post-install"
        TAG_PARAMETER=""
    else
        TAG_PARAMETER="--tags all"
    fi

    bash $WORKSPACE/tripleo-quickstart/quickstart.sh \
        --working-dir $WORKSPACE/ \
        --no-clone \
        --bootstrap \
        --environment $WORKSPACE/config/environments/oooq-internal.yml \
        --teardown all \
        --config $WORKSPACE/config/general_config/$FEATURESET.yml \
        --nodes  $WORKSPACE/config/nodes/$TOPOLOGY.yml \
        --playbook quickstart-extras.yml \
        $TAG_PARAMETER \
        --release $RELEASE \
        -e current_build=$OPT_BUILD_ID \
        ${OPT_VARS[@]} \
        $OPT_ADDITIONAL_PARAMETERS \
        $VIRTHOST

else

    # TODO / NOTE: this is not used at all internally and should be nuked.  It is merely a place to drift
    bash $WORKSPACE/tripleo-quickstart/quickstart.sh \
        --working-dir $WORKSPACE/ \
        --no-clone \
        --bootstrap \
        --environment $WORKSPACE/config/environments/oooq-internal.yml \
        --teardown all \
        --config $WORKSPACE/config/general_config/$CONFIG.yml \
        --playbook quickstart-extras.yml \
        --tags all \
        --release $RELEASE \
        $OPT_ADDITIONAL_PARAMETERS \
        $VIRTHOST

fi
