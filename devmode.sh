#!/bin/bash

: ${GATE:=1}
: ${WORKSPACE:=$HOME/.quickstart}
: ${RELEASE:=master-tripleo-ci}
: ${CONFIG:=minimal}
: ${BUILD_SYS:=delorean}
: ${DEPLOY_TYPE:=libvirt}
: ${ENVIRONMENT:=rdocloud}
: ${CUSTOM_REQUIREMENTS_INSTALL:=none}
: ${DELETE_ALL_STACKS:=false}

interactive=0
reproducer_type=gerrit


usage () {
    echo "Usage: $0 [options] virthost"
    echo ""
    echo "Options:"
    echo "  -c, --config <type> Only minimal.yml config is supported and tested."
    echo "                      specify the node configuration (default=$CONFIG)"
    echo "  -n, --no-gate       do not ask for gating a commit when gating"
    echo "                      variables are missing (default is gating)"
    echo "  -w, --working-dir <dir>"
    echo "                      directory where the virtualenv, inventory files, etc."
    echo "                      are created (default=$WORKSPACE)"
    echo "  -d, --delete-all-stacks"
    echo "                      delete all stacks in the tenant before deployment."
    echo "                      will also delete associated keypairs if they exist."
    echo "  -r, --release <release>"
    echo "                      OpenStack release to deploy (default=$RELEASE)."
    echo "  -h, --help          print this help and exit. Note OVB is no longer supported.
                                See https://docs.openstack.org/tripleo-docs/latest/contributor/reproduce-ci.html"
    echo "  virthost            target machine used for deployment, required argument"
}


zuul-gate () {
    if [[ -z "$ZUUL_HOST" ]]; then
        interactive=1
        echo "Which Zuul host to use? (default=review.openstack.org)"
        read -p "ZUUL_HOST=" ZUUL_HOST
        ZUUL_HOST=${ZUUL_HOST:-"review.openstack.org"}
        echo ""
    fi
    ZUUL_HOST=${ZUUL_HOST:-"review.openstack.org"}
    if [[ -z "$ZUUL_CHANGES" ]]; then
        interactive=1
        echo "Specify ZUUL_CHANGES variable from logs/reproduce.sh"
        read -p "ZUUL_CHANGES=" ZUUL_CHANGES
        echo ""
    fi
    export ZUUL_{HOST,CHANGES}
}

gerrit-gate () {
    if [[ -z "$GERRIT_HOST" ]]; then
        interactive=1
        echo "Which Gerrit host to use? (default=review.openstack.org)"
        read -p "GERRIT_HOST=" GERRIT_HOST
        GERRIT_HOST=${GERRIT_HOST:-"review.openstack.org"}
        echo ""
    fi
    if [[ -z "$GERRIT_BRANCH" ]]; then
        interactive=1
        echo "Which branch is the patch on? (default=master)"
        read -p "GERRIT_BRANCH=" GERRIT_BRANCH
        GERRIT_BRANCH=${GERRIT_BRANCH:-master}
        echo ""
    fi
    if [[ -z "$GERRIT_CHANGE_ID" ]]; then
        interactive=1
        echo "What is the Change-Id? Can be found in the commit message."
        echo "Note: all \"Depends-On:\" changes are going to be built as well."
        read -p "GERRIT_CHANGE_ID=" GERRIT_CHANGE_ID
        echo ""
    fi
    if [[ -z "$GERRIT_PATCHSET_REVISION" ]]; then
        interactive=1
        echo "What is the git commit hash of the patchset?"
        echo "It can be found in the Commit field on Gerrit"
        read -p "GERRIT_PATCHSET_REVISION=" GERRIT_PATCHSET_REVISION
        echo ""
    fi
    export GERRIT_{HOST,BRANCH,CHANGE_ID,PATCHSET_REVISION}
}


interactive-gate () {
    if [[ -n "$ZUUL_HOST" ]]; then
        reproducer_type=zuul
    fi
    if [[ -z "$ZUUL_HOST" && -z "$GERRIT_HOST" ]]; then
        interactive=1
        echo "Do you want to reproduce an environment from an upstream CI Zuul job"
        echo "or use a Gerrit change? (default=gerrit)"
        read -p "[zuul/GERRIT] " reproducer_type
        echo ""
    fi
    if [[ $reproducer_type = 'zuul' ]]; then
        zuul-gate
    else
        gerrit-gate
    fi
    if [[ "$interactive" = "1" ]]; then
        echo "Check if these values are correct:"
    else
        echo "Running with the following variables:"
    fi
    echo ""
    if [[ $reproducer_type = 'zuul' ]]; then
        echo "ZUUL_HOST=$ZUUL_HOST"
        echo "ZUUL_CHANGES=$ZUUL_CHANGES"
        echo "export ZUUL_{HOST,CHANGES}"
    else
        echo "GERRIT_HOST=$GERRIT_HOST"
        echo "GERRIT_BRANCH=$GERRIT_BRANCH"
        echo "GERRIT_CHANGE_ID=$GERRIT_CHANGE_ID"
        echo "GERRIT_PATCHSET_REVISION=$GERRIT_PATCHSET_REVISION"
        echo "export GERRIT_{HOST,BRANCH,CHANGE_ID,PATCHSET_REVISION}"
    fi
    echo ""
    if [[ "$interactive" = "1" ]]; then
        echo "Note: You can re-run this script non-interactively by pasting"
        echo "the lines above to the console before rerunning the script."
        echo "Hit ENTER to continue, or CTRL-C to exit"
        read
    fi
}

while [ "x$1" != "x" ]; do

    case "$1" in
        --working-dir|-w)
            WORKSPACE=$(realpath $2)
            shift
            ;;

        --config|-c)
            CONFIG=$2
            shift
            ;;

        --delete-all-stacks|-d)
            DELETE_ALL_STACKS=true
            ;;

        --no-gate|-n)
            GATE=0
            ;;

        --release|-r)
            RELEASE=$2
            shift
            ;;
        --help|-h)
            usage
            exit
            ;;

        --) shift
            break
            ;;

        -*) echo "ERROR: unknown option: $1" >&2
            usage >&2
            exit 2
            ;;

        *)    break
            ;;
    esac

    shift
done

pushd $(dirname ${BASH_SOURCE[0]:-$0})

# variables needed for the CI script
export VIRTHOST=$1
export WORKSPACE

if [[ -z $VIRTHOST ]]; then
    usage
    echo ""
    echo "Specify the virthost to use. You need to be able to ssh as root without"
    echo "password with your current user (i.e. ssh root@\$VIRTHOST must succeed)"
    exit 1
fi

if [ "$GATE" = "1" ]; then
    interactive-gate
    JOB_TYPE=dlrn-gate
else
    JOB_TYPE=periodic
fi


BASE_QUICKSTART_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


bash $BASE_QUICKSTART_DIR/ci-scripts/full-deploy.sh $RELEASE $BUILD_SYS $CONFIG $JOB_TYPE


popd
