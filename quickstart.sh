#!/bin/bash

: ${OPT_BOOTSTRAP:=0}
: ${OPT_SYSTEM_PACKAGES:=0}
: ${OPT_WORKDIR:=$HOME/.quickstart}

# This creates a Python virtual environment and installs
# tripleo-quickstart into that environment.  It only runs if
# the local working directory does not exist, or if explicitly
# requested via --bootstrap.
bootstrap () {
    virtualenv $( [ "$OPT_SYSTEM_PACKAGES" = 1 ] && printf -- "--system-site-packages\n" ) $OPT_WORKDIR
    . $OPT_WORKDIR/bin/activate

    if ! [ -d "$OPT_WORKDIR/tripleo-quickstart" ]; then
        echo "Cloning tripleo-quickstart repository..."
        git clone https://github.com/redhat-openstack/tripleo-quickstart.git \
            $OPT_WORKDIR/tripleo-quickstart
    fi

    (
    cd $OPT_WORKDIR/tripleo-quickstart
    pip install -r requirements.txt
    python setup.py install
    )
}

usage () {
    echo "$0: usage: $0 [options] virthost [release]"
    echo "$0: options:"
    echo "    --system-site-packages"
    echo "    --bootstrap"
    echo "    --workdir-dir"
    echo "    --undercloud-image-url"
}

while [ "x$1" != "x" ]; do

    case "$1" in
        --system-site-packages|-s)
            OPT_SYSTEM_PACKAGES=1
            ;;

        --bootstrap|-b)
            OPT_BOOTSTRAP=1
            ;;

        --working-dir|-w)
            OPT_WORKDIR=$2
            shift
            ;;

        --undercloud-image-url|-u)
            OPT_UNDERCLOUD_URL=$2
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

if [ "$OPT_BOOTSTRAP" = 1 ] || ! [ -d "$OPT_WORKDIR" ]; then
    bootstrap
fi

# make sure we have an absolute path
OPT_WORKDIR=$(cd $OPT_WORKDIR && pwd)

export ANSIBLE_CONFIG=$OPT_WORKDIR/tripleo-quickstart/ansible.cfg
export ANSIBLE_INVENTORY=$OPT_WORKDIR/hosts

if ! grep -q ssh_args $OPT_WORKDIR/ssh.config.ansible; then
    echo "Setting ssh_args..."
    echo "ssh_args = -F $OPT_WORKDIR/ssh.config.ansible" >> $ANSIBLE_CONFIG
fi

ansible-playbook -vv $OPT_WORKDIR/tripleo-quickstart/playbooks/quickstart.yml \
    -e url=$OPT_UNDERCLOUD_URL \
    -e local_working_dir=$OPT_WORKDIR \
    -e virthost=$VIRTHOST

set +x

cat <<EOF
##################################
Virtual Environment Setup Complete
##################################

Access the undercloud by:

  ssh -F $OPT_WORKDIR/ssh.config.ansible undercloud

Then continue the undercloud install with:

  openstack undercloud install
  source stackrc

##################################
Virtual Environment Setup Complete
##################################
EOF
