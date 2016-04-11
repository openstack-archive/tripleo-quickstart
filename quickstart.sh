#!/bin/bash

DEFAULT_OPT_TAGS="untagged,provision,environment,undercloud-scripts,overcloud-scripts"

: ${OPT_BOOTSTRAP:=0}
: ${OPT_SYSTEM_PACKAGES:=0}
: ${OPT_WORKDIR:=$HOME/.quickstart}
: ${OPT_TAGS:=$DEFAULT_OPT_TAGS}

install_deps () {
    yum -y install \
        /usr/bin/git \
        /usr/bin/virtualenv \
        gcc \
        libyaml \
        libselinux-python
}

# This creates a Python virtual environment and installs
# tripleo-quickstart into that environment.  It only runs if
# the local working directory does not exist, or if explicitly
# requested via --bootstrap.
bootstrap () {
    (   # run in a subshell so that we can 'set -e' without aborting
        # the main script immediately (because we want to clean up
        # on failure).

    set -e

    virtualenv $( [ "$OPT_SYSTEM_PACKAGES" = 1 ] && printf -- "--system-site-packages\n" ) $OPT_WORKDIR
    . $OPT_WORKDIR/bin/activate

    if [ "$OPT_NO_CLONE" != 1 ]; then
        if ! [ -d "$OPT_WORKDIR/tripleo-quickstart" ]; then
            echo "Cloning tripleo-quickstart repository..."
            git clone https://github.com/openstack/tripleo-quickstart.git \
                $OPT_WORKDIR/tripleo-quickstart
        fi

        cd $OPT_WORKDIR/tripleo-quickstart
        if [ -n "$OPT_GERRIT" ]; then
            git review -d "$OPT_GERRIT"
        else
            git remote update
            git checkout --quiet origin/master
        fi
    fi

    pip install -r requirements.txt
    )
}

activate_venv() {
    . $OPT_WORKDIR/bin/activate
}

usage () {
    echo "$0: usage: $0 [options] virthost [release]"
    echo "$0: usage: sudo $0 --install-deps"
    echo "$0: options:"
    echo "    --system-site-packages"
    echo "    --ansible-debug"
    echo "    --bootstrap"
    echo "    --working-dir <directory>"
    echo "    --undercloud-image-url <url>"
    echo "    --tags <tag1>[,<tag2>,...]"
    echo "    --skip-tags <tag1>,[<tag2>,...]"
    echo "    --config <file>"
}

while [ "x$1" != "x" ]; do

    case "$1" in
        --install-deps)
            OPT_INSTALL_DEPS=1
            ;;

        --system-site-packages|-s)
            OPT_SYSTEM_PACKAGES=1
            ;;

        --bootstrap|-b)
            OPT_BOOTSTRAP=1
            ;;

        --ansible-debug|-v)
            OPT_DEBUG_ANSIBLE=1
            ;;

        --working-dir|-w)
            OPT_WORKDIR=$2
            shift
            ;;

        --undercloud-image-url|-u)
            OPT_UNDERCLOUD_URL=$2
            shift
            ;;

        --tags|-t)
            OPT_TAGS=$2
            shift
            ;;

        --skip-tags)
            OPT_SKIP_TAGS=$2
            shift
            ;;

        --config|-c)
            OPT_CONFIG=$2
            shift
            ;;

        --help|-h)
            usage
            exit
            ;;

        # developer options

        --gerrit|-g)
            OPT_GERRIT=$2
            OPT_BOOTSTRAP=1
            shift
            ;;

        --no-clone|-n)
            OPT_NO_CLONE=1
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

if [ "$OPT_NO_CLONE" = 1 ]; then
    OOOQ_DIR=.
else
    OOOQ_DIR=$OPT_WORKDIR/tripleo-quickstart
fi

# Set this default after option processing, because the default depends
# on another option.
: ${OPT_CONFIG:=$OOOQ_DIR/playbooks/centosci/minimal.yml}

if [ "$OPT_INSTALL_DEPS" = 1 ]; then
    echo "NOTICE: installing dependencies"
    install_deps
    exit $?
fi

if [ "$#" -lt 1 ]; then
    echo "ERROR: You must specify a target machine." >&2
    usage >&2
    exit 2
fi

if [ "$#" -gt 2 ]; then
    usage >&2
    exit 2
fi

VIRTHOST=$1
RELEASE=$2

# We use $RELEASE to build the undercloud image URL. If the user has provided
# an explicit URL, then $RELEASE is a no-op so we should warn the user of that
# fact.
if [ -n "$RELEASE" ] && [ -n "$OPT_UNDERCLOUD_URL" ]; then
    echo "WARNING: ignoring release $RELEASE because you have" >&2
    echo "         provided an explicit undercloud image URL." >&2

    RELEASE=
elif [ -z "$RELEASE" ] && [ -z "$OPT_UNDERCLOUD_URL" ]; then
    RELEASE=mitaka
fi

# we use this only if --undercloud-image-url was not provided on the
# command line.
: ${OPT_UNDERCLOUD_URL:=http://artifacts.ci.centos.org/artifacts/rdo/images/${RELEASE}/delorean/stable/undercloud.qcow2}

echo "Installing OpenStack ${RELEASE:+"$RELEASE "}on host $VIRTHOST"
echo "Using directory $OPT_WORKDIR for a local working directory"

if [ "$OPT_BOOTSTRAP" = 1 ] || ! [ -f "$OPT_WORKDIR/bin/activate" ]; then
    bootstrap

    if [ $? -ne 0 ]; then
        echo "ERROR: bootstrap failed; removing $OPT_WORKDIR"
    echo "       try "sudo $0 --install-deps" to install requirements"
        rm -rf $OPT_WORKDIR
        exit 1
    fi
fi

activate_venv

set -ex

export ANSIBLE_CONFIG=$OOOQ_DIR/ansible.cfg
export ANSIBLE_INVENTORY=$OPT_WORKDIR/hosts

if [ "$VIRTHOST" = "localhost" ]; then
    echo "$0: WARNING: VIRTHOST == localhost; skipping provisioning" >&2
    OPT_SKIP_TAGS="${OPT_SKIP_TAGS:+$OPT_SKIP_TAGS,}provision"

    echo "[virthost]" > $ANSIBLE_INVENTORY
    echo "localhost ansible_connection=local" >> $ANSIBLE_INVENTORY
fi

if [ "$OPT_DEBUG_ANSIBLE" = 1 ]; then
    VERBOSITY=vvvv
else
    VERBOSITY=vv
fi

ansible-playbook -$VERBOSITY $OOOQ_DIR/playbooks/quickstart.yml \
    -e @$OPT_CONFIG \
    -e ansible_python_interpreter=/usr/bin/python \
    -e image_url=$OPT_UNDERCLOUD_URL \
    -e local_working_dir=$OPT_WORKDIR \
    -e virthost=$VIRTHOST \
    ${OPT_TAGS:+-t $OPT_TAGS} \
    ${OPT_SKIP_TAGS:+--skip-tags $OPT_SKIP_TAGS}

# We only print out further usage instructions when using the default
# tags, since this is for new users (and not even applicable to some tags).

set +x

if [ $OPT_TAGS = $DEFAULT_OPT_TAGS ] ; then

cat <<EOF
##################################
Virtual Environment Setup Complete
##################################

Access the undercloud by:

    ssh -F $OPT_WORKDIR/ssh.config.ansible undercloud

There are scripts in the home directory to continue the deploy:

    undercloud-install.sh will run the undercloud install
    undercloud-post-install.sh will perform all pre-deploy steps
    overcloud-deploy.sh will deploy the overcloud
    overcloud-deploy-post.sh will do any post-deploy configuration
    overcloud-validate.sh will run post-deploy validation

Alternatively, you can ignore these scripts and follow the upstream docs:

First:

    openstack undercloud install
    source stackrc

Then continue with the instructions (limit content using dropdown on the left):

    http://ow.ly/Ze8nK

##################################
Virtual Environment Setup Complete
##################################
EOF
fi
