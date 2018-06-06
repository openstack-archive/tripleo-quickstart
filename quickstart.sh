#!/bin/bash
# Show colored output if running interactively
if [ -t 1 ] ; then
    export ANSIBLE_FORCE_COLOR=true
fi
# Log everything from this script into _quickstart.log
echo "$0 $@" > _quickstart.log
exec &> >(tee -i -a _quickstart.log )

# With LANG set to everything else than C completely undercipherable errors
# like "file not found" and decoding errors will start to appear during scripts
# or even ansible modules
LANG=C

DEFAULT_OPT_TAGS="untagged,provision,environment,libvirt,undercloud-scripts,undercloud-inventory,overcloud-scripts,undercloud-setup,undercloud-install,undercloud-post-install,tripleoui-validate"
ZUUL_CLONER=/usr/zuul-env/bin/zuul-cloner

: ${OPT_BOOTSTRAP:=0}
: ${OPT_CLEAN:=0}
: ${OPT_PLAYBOOK:=quickstart-extras.yml}
: ${OPT_RELEASE:=queens}
: ${OPT_RETAIN_INVENTORY_FILE:=0}
: ${OPT_SYSTEM_PACKAGES:=0}
: ${OPT_TAGS:=$DEFAULT_OPT_TAGS}
: ${OPT_TEARDOWN:=nodes}
: ${OPT_WORKDIR:=$HOME/.quickstart}
: ${OPT_LIST_TASKS_ONLY=""}

clean_virtualenv() {
    if [ -d $OPT_WORKDIR ]; then
        echo "WARNING: Removing $OPT_WORKDIR. Triggering virtualenv bootstrap."
        rm -rf $OPT_WORKDIR
    fi
}

: ${OOOQ_BASE_REQUIREMENTS:=requirements.txt}
: ${OOOQ_EXTRA_REQUIREMENTS:=quickstart-extras-requirements.txt}

install_deps () {
    # If sudo isn't installed assume we already are a super user
    # install it anyways so that the install of the other deps succeeds
    sudo true || yum install -y sudo
    sudo yum -y install \
        /usr/bin/git \
        /usr/bin/virtualenv \
        gcc \
        iproute \
        libyaml \
        libselinux-python \
        libffi-devel \
        openssl-devel \
        redhat-rpm-config
}


print_logo () {

if [ `TERM=${TERM:-vt100} tput cols` -lt 105 ]; then

cat <<EOBANNER
----------------------------------------------------------------------------
|                                ,   .   ,                                 |
|                                )-_'''_-(                                 |
|                               ./ o\ /o \.                                |
|                              . \__/ \__/ .                               |
|                              ...   V   ...                               |
|                              ... - - - ...                               |
|                               .   - -   .                                |
|                                \`-.....-´                                 |
|   ____         ____      ____        _      _        _             _     |
|  / __ \       / __ \    / __ \      (_)    | |      | |           | |    |
| | |  | | ___ | |  | |  | |  | |_   _ _  ___| | _____| |_ __ _ _ __| |_   |
| | |  | |/ _ \| |  | |  | |  | | | | | |/ __| |/ / __| __/ _\` | '__| __|  |
| | |__| | |_| | |__| |  | |__| | |_| | | (__|   <\__ \ |_|(_| | |  | |_   |
|  \____/ \___/ \____/    \___\_\\\__,_|_|\___|_|\_\___/\__\__,_|_|   \__|  |
|                                                                          |
|                                                                          |
----------------------------------------------------------------------------


EOBANNER

else

cat <<EOBANNER
-------------------------------------------------------------------------------------------------------
|     ,   .   ,   _______   _       _       ____      ____        _      _        _             _     |
|     )-_'''_-(  |__   __| (_)     | |     / __ \    / __ \      (_)    | |      | |           | |    |
|    ./ o\ /o \.    | |_ __ _ _ __ | | ___| |  | |  | |  | |_   _ _  ___| | _____| |_ __ _ _ __| |_   |
|   . \__/ \__/ .   | | '__| | '_ \| |/ _ \ |  | |  | |  | | | | | |/ __| |/ / __| __/ _\` | '__| __|  |
|   ...   V   ...   | | |  | | |_) | |  __/ |__| |  | |__| | |_| | | (__|   <\__ \ |_|(_| | |  | |_   |
|   ... - - - ...   |_|_|  |_| .__/|_|\___|\____/    \___\_\\\__,_|_|\___|_|\_\___/\__\__,_|_|   \__|  |
|    .   - -   .             | |                                                                      |
|     \`-.....-´              |_|                                                                      |
-------------------------------------------------------------------------------------------------------


EOBANNER

fi
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

    virtualenv\
        $( [ "$OPT_SYSTEM_PACKAGES" = 1 ] && printf -- "--system-site-packages\n" )\
        $OPT_WORKDIR
    . $OPT_WORKDIR/bin/activate
    pip install pip --upgrade

    if [ "$OPT_NO_CLONE" != 1 ]; then
        if ! [ -d "$OOOQ_DIR" ]; then
            echo "Cloning tripleo-quickstart repository..."
            git clone https://github.com/openstack/tripleo-quickstart.git \
                $OOOQ_DIR
        fi

        cd $OOOQ_DIR
        if [ -n "$OPT_GERRIT" ]; then
            git review -d "$OPT_GERRIT"
        else
            git remote update
            git checkout --quiet origin/master
        fi
    fi

    pushd $OOOQ_DIR
        python setup.py install egg_info --egg-base $OPT_WORKDIR || { echo 'python setup.py install failed' ; exit 1; }
        pip install --force-reinstall "${OPT_REQARGS[@]}" || { echo 'python setup.py install failed' ; exit 1; }
        if [ -x "$ZUUL_CLONER" ] && [ ! -z "$ZUUL_BRANCH" ]; then
            mkdir -p .tmp
            EXTRAS_DIR=$(/bin/mktemp -d -p $(pwd)/.tmp)
            pushd $EXTRAS_DIR
                $ZUUL_CLONER --cache-dir \
                    /opt/git \
                    git://git.openstack.org \
                    openstack/tripleo-quickstart-extras
                cd openstack/tripleo-quickstart-extras
                pip install  .
            popd
        fi
    popd
    )
    # In order to do any filesystem operations on the system running ansible (if it has SELinux intalled)
    # we need the python bindings in the venv. Unfortunately, it is not available on pypi, so we need to
    # pull it from the system site packages.
    copy_selinux_to_venv
}

copy_selinux_to_venv() {
    : ${LIBSELINUX_PYTHON_PATH:=lib64/python2.7/site-packages}
    cp -R /usr/$LIBSELINUX_PYTHON_PATH/selinux $OPT_WORKDIR/$LIBSELINUX_PYTHON_PATH/ || true
    # on Fedora the _selinux.so is one dir up for some reason
    cp /usr/$LIBSELINUX_PYTHON_PATH/_selinux.so $OPT_WORKDIR/$LIBSELINUX_PYTHON_PATH/ || true
}

activate_venv() {
    . $OPT_WORKDIR/bin/activate
}

usage () {
    echo "Usage: $0 --install-deps"
    echo "                      install quickstart package dependencies and exit"
    echo ""
    echo "Usage: $0 [options] <virthost>"
    echo ""
    echo "  virthost            a physical machine hosting the libvirt VMs of the TripleO"
    echo "                      deployment, required argument"
    echo ""
    echo "Basic options:"
    echo "  -p, --playbook <file>"
    echo "                      playbook to run, relative to playbooks directory"
    echo "                      (default=$OPT_PLAYBOOK)"
    echo "  -r, --requirements <file>"
    echo "                      install requirements with pip, can be used"
    echo "                      multiple times. By using this flag you override "
    echo "                      both requirements.txt and quickstart-extras-requirements.txt."
    echo "                      The user assumes responsibility for the requirements. "
    echo "  -R, --release       OpenStack release to deploy (default=$OPT_RELEASE)"
    echo "  -c, --config <file>"
    echo "                      specify the config file that contains the node"
    echo "                      configuration, can be used only once"
    echo "                      (default=config/general_config/minimal.yml)"
    echo "  -N, --nodes <file>"
    echo "                      specify the number of nodes that should be created by"
    echo "                      the provisioner. "
    echo "  -E, --environment <file>"
    echo "                      specify additional configuration that is specific to"
    echo "                      the environment where TripleO-Quickstart is running."
    echo "  -e, --extra-vars <key>=<value>"
    echo "                      additional ansible variables, can be used multiple times"
    echo "  -w, --working-dir <dir>"
    echo "                      directory where the virtualenv, inventory files, etc."
    echo "                      are created (default=$OPT_WORKDIR)"
    echo ""
    echo "Advanced options:"
    echo "  -v, --ansible-debug"
    echo "                      invoke ansible-playbook with -vvvv"
    echo "  -y, --dry-run"
    echo "                      dry run of playbook, invoke ansible with --list-tasks"
    echo "  -X, --clean         discard the working directory on start"
    echo "  -b, --bootstrap     force creation of the virtualenv and the installation"
    echo "                      of requirements without discarding the working directory"
    echo "  -n, --no-clone      skip cloning the tripleo-quickstart repo, use quickstart"
    echo "                      code from \$PWD"
    echo "  -g, --gerrit <change-id>"
    echo "                      check out <change-id> for the tripleo-quickstart repo"
    echo "                      before running the playbook"
    echo "  -I, --retain-inventory"
    echo "                      keep the ansible inventory on start, used for consecutive"
    echo "                      runs of quickstart on the same environment"
    echo "  -s, --system-site-packages"
    echo "                      give access to the global site-packages modules"
    echo "                      to the virtualenv"
    echo "  -t, --tags <tag1>[,<tag2>,...]"
    echo "                      only run plays and tasks tagged with these values,"
    echo "                      specify 'all' to run everything"
    echo "                      (default=$OPT_TAGS)"
    echo "  -T, --teardown [ all | virthost | nodes | none ]"
    echo "                      parts of a previous deployment to tear down before"
    echo "                      starting a new one, see the docs for full description"
    echo "                      (default=$OPT_TEARDOWN)"
    echo "  -S, --skip-tags <tag1>[,<tag2>,...]"
    echo "                      only run plays and tasks whose tags do"
    echo "                      not match these values"
    echo "  -l, --print-logo    print the TripleO logo and exit"
    echo "  -h, --help          print this help and exit"

}

OPT_VARS=()
OPT_ENVIRONMENT=()

while [ "x$1" != "x" ]; do
    case "$1" in
        --install-deps|-i)
            OPT_INSTALL_DEPS=1
            ;;

        --system-site-packages|-s)
            OPT_SYSTEM_PACKAGES=1
            ;;

        --requirements|-r)
            OPT_REQARGS+=("-r")
            OPT_REQARGS+=("$2")
            shift
            ;;

        --release|-R)
            OPT_RELEASE=$2
            shift
            ;;

        --bootstrap|-b)
            OPT_BOOTSTRAP=1
            ;;

        --ansible-debug|-v)
            OPT_DEBUG_ANSIBLE=1
            ;;

        --working-dir|-w)
            OPT_WORKDIR=$(realpath $2)
            shift
            ;;

        --tags|-t)
            OPT_TAGS=$2
            shift
            ;;

        --skip-tags|-S)
            OPT_SKIP_TAGS=$2
            shift
            ;;

        --config|-c)
            OPT_CONFIG=$2
            shift
            ;;

        --nodes|-N)
            OPT_NODES=$2
            shift
            ;;

        --environment|-E)
            OPT_ENVIRONMENT+=("-e")
            OPT_ENVIRONMENT+=("@$2")
            shift
            ;;

        --clean|-X)
            OPT_CLEAN=1
            ;;

        --playbook|-p)
            OPT_PLAYBOOK=$2
            shift
            ;;

        --extra-vars|-e)
            OPT_VARS+=("-e")
            OPT_VARS+=("$2")
            shift
            ;;

        --teardown|-T)
            OPT_TEARDOWN=$2
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

        --dry-run|-y)
            OPT_LIST_TASKS_ONLY=" --list-tasks"
            ;;

        --no-clone|-n)
            OPT_NO_CLONE=1
            ;;

        --retain-inventory|-I)
            OPT_RETAIN_INVENTORY_FILE=1
            ;;

        --print-logo|-l)
            PRINT_LOGO=1
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

if [ -z "$OPT_REQARGS" ]; then
    OPT_REQARGS=("-r"  "$OOOQ_BASE_REQUIREMENTS" "-r" "$OOOQ_EXTRA_REQUIREMENTS")
fi

if [ "$PRINT_LOGO" = 1 ]; then
    print_logo
    echo "..."
    echo "Nothing more to do"
    exit
fi


if [ "$OPT_NO_CLONE" = 1 ]; then
    SCRIPT=$( readlink -f "${BASH_SOURCE[0]}" )
    THIS_DIR=$( dirname $SCRIPT )
    OOOQ_DIR=$THIS_DIR
else
    OOOQ_DIR=$OPT_WORKDIR/tripleo-quickstart
fi

if [ "$OPT_CLEAN" = 1 ]; then
    clean_virtualenv
fi

if [ "$OPT_TEARDOWN" = "all" ]; then
    OPT_TAGS="${OPT_TAGS:+$OPT_TAGS,}teardown-all"
elif [ "$OPT_TEARDOWN" = "virthost" ]; then
    OPT_TAGS="${OPT_TAGS:+$OPT_TAGS,}teardown-nodes,teardown-environment"
elif [ "$OPT_TEARDOWN" = "nodes" ]; then
    OPT_TAGS="${OPT_TAGS:+$OPT_TAGS,}teardown-nodes"
elif [ "$OPT_TEARDOWN" = "none" ]; then
    OPT_SKIP_TAGS="${OPT_SKIP_TAGS:+$OPT_SKIP_TAGS,}teardown-all"
fi

# Set this default after option processing, because the default depends
# on another option.
# Default general configuration
: ${OPT_CONFIG:=$OPT_WORKDIR/config/general_config/minimal.yml}
# Default Nodes
: ${OPT_NODES:=$OPT_WORKDIR/config/nodes/1ctlr_1comp.yml}
# Default Environment
: ${OPT_ENVIRONMENT:=-e @$OPT_WORKDIR/config/environments/default_libvirt.yml}

# allow the deprecated config files to work
OLD_CONFIG=""
if [[ "$OPT_CONFIG" =~ (^|.*/)ha.yml$ ]]; then
    OLD_CONFIG=$OPT_CONFIG
    OPT_CONFIG=$OPT_WORKDIR/config/general_config/pacemaker.yml;
    OPT_NODES=$OPT_WORKDIR/config/nodes/3ctlr_1comp.yml;
elif [[ "$OPT_CONFIG" =~ (^|.*/)ceph.yml$ ]]; then
    OLD_CONFIG=$OPT_CONFIG
    OPT_CONFIG=$OPT_WORKDIR/config/general_config/minimal.yml;
    OPT_NODES=$OPT_WORKDIR/config/nodes/1ctlr_1comp_1ceph.yml;
elif [[ "$OPT_CONFIG" =~ (^|.*/)ha_big.yml$ ]]; then
    OLD_CONFIG=$OPT_CONFIG
    OPT_CONFIG=$OPT_WORKDIR/config/general_config/pacemaker.yml;
    OPT_NODES=$OPT_WORKDIR/config/nodes/3ctlr_3comp.yml;
elif [[ "$OPT_CONFIG" =~ (^|.*/)fake_ha_ipa.yml$ ]]; then
    OLD_CONFIG=$OPT_CONFIG
    OPT_CONFIG=$OPT_WORKDIR/config/general_config/ipa.yml;
    OPT_NODES=$OPT_WORKDIR/config/nodes/1ctlr_1comp_1supp.yml;
elif [[ "$OPT_CONFIG" =~ (^|.*/)ha_ipa.yml$ ]]; then
    OLD_CONFIG=$OPT_CONFIG
    OPT_CONFIG=$OPT_WORKDIR/config/general_config/ipa.yml;
    OPT_NODES=$OPT_WORKDIR/config/nodes/3ctlr_1comp.yml;
elif [[ "$OPT_CONFIG" =~ (^|.*/)ha_ipv6.yml$ ]]; then
    OLD_CONFIG=$OPT_CONFIG
    OPT_CONFIG=$OPT_WORKDIR/config/general_config/ipv6.yml;
    OPT_NODES=$OPT_WORKDIR/config/nodes/3ctlr_1comp.yml;
elif [[ "$OPT_CONFIG" =~ (^|.*/)minimal_pacemaker.yml$ ]]; then
    OLD_CONFIG=$OPT_CONFIG
    OPT_CONFIG=$OPT_WORKDIR/config/general_config/pacemaker.yml;
fi

if [ "$OLD_CONFIG" != "" ]; then
    echo "******************** PLEASE READ ****************************"
    echo ""
    echo "DEPRECATION NOTICE: $OLD_CONFIG has been deprecated"
    echo ""
    sleep 3;
fi

if [ "$OPT_INSTALL_DEPS" = 1 ]; then
    echo "NOTICE: installing dependencies"
    install_deps
    exit $?
fi

if [ "$OPT_BOOTSTRAP" = 1 ] || ! [ -f "$OPT_WORKDIR/bin/activate" ]; then
    bootstrap

    if [ $? -ne 0 ]; then
        echo "ERROR: bootstrap failed; try \"$0 --install-deps\""
        echo "       to install package dependencies or \"$0 --clean\""
        echo "       to remove $OPT_WORKDIR and start over"
        exit 1
    fi
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

print_logo
echo "Installing OpenStack ${OPT_RELEASE:+"$OPT_RELEASE "}on host $VIRTHOST"
echo "Using directory $OPT_WORKDIR for a local working directory"
echo "Current run is logged in _quickstart.log file in current directory"

set -ex

activate_venv

export ANSIBLE_CONFIG=$OOOQ_DIR/ansible.cfg
export ANSIBLE_INVENTORY=$OPT_WORKDIR/hosts
export ARA_DATABASE="sqlite:///${OPT_WORKDIR}/ara.sqlite"

#set the ansible ssh.config options if not already set.
source $OOOQ_DIR/ansible_ssh_env.sh

if [ "$OPT_RETAIN_INVENTORY_FILE" = 0 && -z "$OPT_LIST_TASKS_ONLY" ]; then
    # Clear out inventory file to avoid tripping over data
    # from a previous invocation
    rm -f $ANSIBLE_INVENTORY
fi

if [ "$OPT_DEBUG_ANSIBLE" = 1 ]; then
    VERBOSITY=vvvv
else
    VERBOSITY=vv
fi

ansible-playbook -$VERBOSITY $OPT_WORKDIR/playbooks/$OPT_PLAYBOOK \
    -e @$OPT_WORKDIR/config/release/$OPT_RELEASE.yml \
    -e @$OPT_NODES \
    -e @$OPT_CONFIG \
    ${OPT_ENVIRONMENT[@]} \
    -e local_working_dir=$OPT_WORKDIR \
    ${OPT_LIST_TASKS_ONLY} \
    -e virthost=$VIRTHOST \
    ${OPT_VARS[@]} \
    ${OPT_TAGS:+-t $OPT_TAGS} \
    ${OPT_SKIP_TAGS:+--skip-tags $OPT_SKIP_TAGS}

# We only print out further usage instructions when using the default
# tags, since this is for new users (and not even applicable to some tags).

set +x

if ! [[ "overcloud-deploy" =~ .*$OPT_TAGS.* ]] && [[ $OPT_PLAYBOOK == quickstart-extras.yml ]]; then

cat <<EOF
##################################
Virtual Environment Setup Complete
##################################

Access the undercloud by:

    ssh -F $OPT_WORKDIR/ssh.config.ansible undercloud

Follow the documentation in the link below to complete your deployment.

    http://ow.ly/c44w304begR

##################################
Virtual Environment Setup Complete
##################################
EOF
fi

