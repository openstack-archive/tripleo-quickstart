#!/bin/bash

DEFAULT_OPT_TAGS="untagged,undercloud-scripts,overcloud-scripts"

: ${OPT_BOOTSTRAP:=0}
: ${OPT_SYSTEM_PACKAGES:=0}
: ${OPT_WORKDIR:=$HOME/.quickstart}
: ${OPT_TAGS:=$DEFAULT_OPT_TAGS}

# Install commands before using them.
ensure_command() {
    command -v $1 || yum -y install /usr/bin/$1
}

# This creates a Python virtual environment and installs
# tripleo-quickstart into that environment.  It only runs if
# the local working directory does not exist, or if explicitly
# requested via --bootstrap.
bootstrap () {
    ensure_command virtualenv
    virtualenv $( [ "$OPT_SYSTEM_PACKAGES" = 1 ] && printf -- "--system-site-packages\n" ) $OPT_WORKDIR
    . $OPT_WORKDIR/bin/activate

    if ! [ -d "$OPT_WORKDIR/tripleo-quickstart" ]; then
        echo "Cloning tripleo-quickstart repository..."
        ensure_command git
        git clone https://github.com/redhat-openstack/tripleo-quickstart.git \
            $OPT_WORKDIR/tripleo-quickstart
    fi

    (
    cd $OPT_WORKDIR/tripleo-quickstart
    ensure_command pip
    pip install -r requirements.txt
    python setup.py install
    )
}

activate_venv() {
    . $OPT_WORKDIR/bin/activate
}

usage () {
    echo "$0: usage: $0 [options] virthost [release]"
    echo "$0: options:"
    echo "    --system-site-packages"
    echo "    --ansible-debug"
    echo "    --bootstrap"
    echo "    --working-dir"
    echo "    --undercloud-image-url"
    echo "    --tags"
}

while [ "x$1" != "x" ]; do

    case "$1" in
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

if [ "$#" -lt 1 ]; then
    echo "ERROR: You must specify a target machine." >&2
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
: ${OPT_UNDERCLOUD_URL:=https://ci.centos.org/artifacts/rdo/images/${RELEASE}/delorean/stable/undercloud.qcow2}

echo "Installing OpenStack ${RELEASE:+"$RELEASE "}on host $VIRTHOST"
echo "Using directory $OPT_WORKDIR for a local working directory"

set -ex

if [ "$OPT_BOOTSTRAP" = 1 ] || ! [ -f "$OPT_WORKDIR/bin/activate" ]; then
    bootstrap
else
    activate_venv
fi

# make sure we have an absolute path
OPT_WORKDIR=$(cd $OPT_WORKDIR && pwd)

export ANSIBLE_CONFIG=$OPT_WORKDIR/tripleo-quickstart/ansible.cfg
export ANSIBLE_INVENTORY=$OPT_WORKDIR/hosts

if [ "$OPT_DEBUG_ANSIBLE" = 1 ]; then
    VERBOSITY=vvvv
else
    VERBOSITY=vv
fi

ansible-playbook -$VERBOSITY $OPT_WORKDIR/tripleo-quickstart/playbooks/quickstart.yml \
    -e url=$OPT_UNDERCLOUD_URL \
    -e local_working_dir=$OPT_WORKDIR \
    -e virthost=$VIRTHOST \
    -t $OPT_TAGS

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
