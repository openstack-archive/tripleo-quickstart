#!/bin/bash
# Formally part of quickstart.sh
# Now broken out for more reuse
# install-deps.sh

# atm mvp for the reproducer is python2 only
# expect this option to be removed once
# python2 and python3 have been validated

print_sudo_warning() {
    echo -e "\e[31m WARNING: SUDO user is not passwordless.\
\n export USER_OVERRIDE_SUDO_CHECK=1 \n to be prompted for sudo \
password.  \e[0m"
}

python_cmd() {
    distribution=unknown
    distribution_major_version=unknown
    # we prefer python2 because on few systems python->python3

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        distribution_major_version=${VERSION_ID%.*}
        distribution=${ID}
        PYTHON_CMD=python2
        # check /etc/os-release to see how these variables are set
        case ${ID} in
            rhel)
                distribution="RedHat"
                if [ "$distribution_major_version" -ge "8" ]; then
                    PYTHON_CMD=python3
                fi
                ;;
            centos)
                distribution="CentOS"
                if [ "$distribution_major_version" -ge "8" ]; then
                    PYTHON_CMD=python3
                elif [ "$distribution_major_version" -eq "7" ]; then
                    release_val=$(cat /etc/centos-release | awk '{print $4 }' | grep '^7.8\|^7.9')
                    python_val=$(rpm -q python3)
                    if [ ! -z $release_val ] && [[ $python_val =~ "python3-" ]]; then
                        # declare centos7 python3 variable:
                        centos7py3=true
                        PYTHON_CMD=python3
                    fi
                fi
                ;;
            fedora)
                distribution="Fedora"
                if [ "$distribution_major_version" -ge "28" ]; then
                    PYTHON_CMD=python3
                fi
                ;;
            ubuntu)
                distribution="Ubuntu"
                ;;
            debian)
                distribution="Debian"
                ;;
            esac
        python_cmd=${USER_PYTHON_OVERRIDE:-$PYTHON_CMD}
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        distribution=${DISTRIB_ID}xx
        distribution_major_version=${DISTRIB_RELEASE%.*}
    elif [ -f /etc/debian_version ]; then
        distribution="Debian"
        distribution_major_version=$(cat /etc/debian_version | cut -d. -f1)
    else
        # Covers for FreeBSD and many others
        distribution=$(uname -s)
        if [ $distribution = Darwin ]; then
            distribution="MacOSX"
            distribution_major_version=$(sw_vers -productVersion | cut -d. -f1)
        fi
        which $python_cmd 2>&1 >/dev/null || {
            python_cmd=/usr/local/bin/python2.7
        }
    fi
    echo $python_cmd
}

package_manager() {
    PKG="$(command -v dnf || command -v yum)"
    if [ "$(python_cmd)" == "python3" ]; then
        echo "${PKG} -y --exclude='python2*' $*"
    else
        echo "${PKG} -y --exclude='python3*' $*"
    fi
}

check_python_module () {
    # validate module import and print package versions on single final line
    $(python_cmd) -c "from __future__ import print_function; import $1; print('$1:%s ' % $1.__version__, end='')"
}


install_deps () {
    # zuul no longer provides the git hash for checked out repos.
    # tell me the hash of tripleo-quickstart that is running
    echo "Print out the commit hash of the git repo"
    git show --summary 2>/dev/null || true

    # If sudo isn't installed assume we already are a super user
    # install it anyways so that the install of the other deps succeeds

    # install enough rpms for the appropriate python version to
    # enable bindep and python environments
    echo "Python Command is:"
    python_cmd
    echo "Running install_deps"
    PYTHON_PACKAGES=()
    MODULE_NAMES="pip virtualenv setuptools"
    rpm -q sudo || $(package_manager) install sudo
    sudo -n true && passwordless_sudo="1" || passwordless_sudo="0"
    if [[ "$passwordless_sudo" == "1" ]] || [ "$USER_OVERRIDE_SUDO_CHECK" == "1" ]; then
        if [ "$(python_cmd)" == "python3" ]; then
            echo "setting up for python3"
            # possible bug in ansible, f29 python 3 env fails
            # w/o both python-libselinux packages installed
            # https://bugs.launchpad.net/tripleo/+bug/1812324
            PYTHON_PACKAGES+=("python3-libselinux")
            PYTHON_PACKAGES+=("python3-PyYAML")
            SETUPTOOLS_PACKAGE=python3-setuptools
            if [ -z $centos7py3 ]; then
                VIRTUALENV_PACKAGE=python3-virtualenv
            fi
            PIP_PACKAGE=python3-pip
            if [ -e "/usr/bin/pip3" ]; then
                # centos-8 installs pip as pip3
                sudo alternatives --install /usr/bin/pip pip /usr/bin/pip3 1
            fi
        else
            echo "setting up for python2"
            PYTHON_PACKAGES+=("libselinux-python")
            SETUPTOOLS_PACKAGE=python2-setuptools
            VIRTUALENV_PACKAGE=python2-virtualenv
            PIP_PACKAGE=python-pip
        fi
        echo "Installing RPM packages $PYTHON_PACKAGES $SETUPTOOLS_PACKAGE \
        $VIRTUALENV_PACKAGE $PIP_PACKAGE" | tr -s [:space:]
        sudo $(package_manager) install $PYTHON_PACKAGES \
                                            $SETUPTOOLS_PACKAGE \
                                            $PIP_PACKAGE
        # Install python3 virtualenv via pip on CentOS7
        if [ -z $centos7py3 ]; then
            sudo $(package_manager) install $VIRTUALENV_PACKAGE
        else
            sudo $(python_cmd) -m pip install virtualenv
            sudo $(package_manager) install gcc python3-devel
        fi
        check_python_module virtualenv &> /dev/null || \
            PYTHON_PACKAGES+=($VIRTUALENV_PACKAGE)

        check_python_module setuptools &> /dev/null || \
            PYTHON_PACKAGES+=($SETUPTOOLS_PACKAGE)

    else
        print_sudo_warning
    fi

    # pip is a special case because centos-7 repos do not have an rpm for
    # it but EPEL or OSP repos do, so we attempt to install the rpm and
    # fallback to easy_install before failing
    echo "checking python modules"
    check_python_module pip &> /dev/null || {
        if yum provides pip 2>&1 | grep 'No matches found' >/dev/null; then
            sudo easy_install pip
        fi
    }

    MISSING_MODULES=()
    for module_name in $MODULE_NAMES; do
        check_python_module $module_name || MISSING_MODULES+=("$module_name")
    done
    if [[ -n $MISSING_MODULES ]]; then
        echo "ERROR: ${MISSING_MODULES[@]} not installed" 1>&2
        return 1
    else
        echo -e "\n\e[32m SUCCESS: install-deps succeeded. \e[0m"
    fi
}

install_virtual_env(){
    # Activate the virtualenv only when it is not already activated otherwise
    # It create the virtualenv and then activate it.
    export PYTHONWARNINGS=ignore:DEPRECATION::pip._internal.cli.base_command
    export PIP_DISABLE_PIP_VERSION_CHECK=1
    # Avoids WARNING: The script ... is installed in '/home/zuul/.local/bin' which is not on PATH.
    export PIP_OPTS="${PIP_OPTS:---no-warn-script-location}"

    if [[ -z ${VIRTUAL_ENV+x} ]]; then

        if [[ -f $OPT_WORKDIR/bin/activate ]]; then
            echo "Warning: $OPT_WORKDIR virtualenv already exists, just activating it."
        else
            echo "Creating virtualenv at $OPT_WORKDIR"
            $(python_cmd) -m virtualenv \
                $( [ "$OPT_SYSTEM_PACKAGES" = 1 ] && printf -- "--system-site-packages\n" )\
                $OPT_WORKDIR
        fi

        . $OPT_WORKDIR/bin/activate

    else
        echo "Warning: VIRTUAL_ENV=$VIRTUAL_ENV was found active and is being reused."
    fi

    # Latest pip break Centos7 details in Bug: #1889357, Pin pip to last good version - 20.1.1 for C7
    if [[ $(python_cmd) == 'python2' ]]; then
        $(python_cmd) -m pip install pip==20.1.1
    else
        $(python_cmd) -m pip install pip --upgrade
    fi

    echo "Installing bindep"
    $(python_cmd) -m pip install bindep --upgrade

    # In order to do any filesystem operations on the system running ansible (if it has SELinux installed)
    # we need the python bindings in the venv. The pypi version of the module is a shim that loads
    # the original version from outside the virtualenv.
    $(python_cmd) -c "import selinux" 2>/dev/null ||
        $(python_cmd) -m pip install selinux --upgrade
}

install_bindep(){
    # --user installs fail from a virtenv
    echo "Running install_bindep"
    $(python_cmd) -m pip install --user bindep --upgrade
    export PATH=$PATH:$HOME/.local/bin
    echo -e "\n\e[32m SUCCESS: installed bindep. \e[0m"
}

install_package_deps_via_bindep(){
    echo "install_package_deps_via_bindep"
    sudo -n true && passwordless_sudo="1" || passwordless_sudo="0"
    if [ "$passwordless_sudo" == "1" ] || [ "$USER_OVERRIDE_SUDO_CHECK" == "1" ]; then
        PATH=$PATH:~/.local/bin bindep -b || sudo $(package_manager) install `bindep -b`;
        # EPEL will NOT be installed on any nodepool nodes.
        # EPEL could be installed in the same transaction as other packages on CentOS/RHEL
        # This can leave the system with an older ansible version. Ansible 2.7+ required
        # Run through the deps and update them
        yum-config-manager enable epel || true
        sudo $(package_manager) update `bindep -b -l newline`
    else
        print_sudo_warning
    fi
    echo -e "\n\e[32m SUCCESS: installed required packages via bindep. \e[0m"

}

bootstrap_ansible_via_rpm(){
    echo "Running bootstrap_ansible_via_rpm"
    if [ "$(python_cmd)" == "python3" ]; then
        PACKAGES="python3-libselinux ansible ansible-python3 git rsync python3-netaddr"
    elif [ "$(python_cmd)" == "python2" ]; then
        PACKAGES=("python2-libselinux ansible git rsync python2-netaddr.noarch")
    else
        echo "ERROR: invalid python version"
    fi
    sudo -n true && passwordless_sudo="1" || passwordless_sudo="0"
    if [ "$passwordless_sudo" == "1" ] || [ "$USER_OVERRIDE_SUDO_CHECK" == "1" ]; then
        sudo $(package_manager) install $PACKAGES;
    else
        print_sudo_warning
    fi
}

# This enables a user to install rpm dependencies directly
# from this script.

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # This is not meant be an interactive script
    # however, if users want to install by hand
    # the option is provided.

    # install just enough python
    install_deps
    # install bindep
    install_bindep
    # checks the $PWD for a file named
    # bindep_python[2,3].txt and installs
    # dependencies listed in the file.
    install_package_deps_via_bindep
fi
