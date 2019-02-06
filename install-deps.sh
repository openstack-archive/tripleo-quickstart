#!/bin/bash
# Formally part of quickstart.sh
# Now broken out for more reuse
# install-deps.sh

python_cmd() {
    distribution=unknown
    distribution_major_version=unknown
    # we prefer python2 because on few systems python->python3
    python_cmd=python2

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        distribution_major_version=${VERSION_ID%.*}
        case $NAME in
        "Red Hat"*) distribution="RedHat"
            if [ "$distribution_major_version" -ge "8" ]; then
                python_cmd=python3
            fi
            ;;
        "CentOS"*)
            distribution="CentOS"
            if [ "$distribution_major_version" -ge "8" ]; then
                python_cmd=python3
            fi
            ;;
        "Fedora"*)
            distribution="Fedora"
            if [ "$distribution_major_version" -ge "28" ]; then
                python_cmd=python3
            fi
            ;;
        "Ubuntu"*)
            distribution="Ubuntu"
            ;;
        "Debian"*)
            distribution="Debian"
            ;;
        esac
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
    # If sudo isn't installed assume we already are a super user
    # install it anyways so that the install of the other deps succeeds
    PYTHON_PACKAGES=()
    MODULE_NAMES="pip virtualenv setuptools"
    rpm -q sudo || $(package_manager) install -y sudo
    sudo -n true && passwordless_sudo="1" || passwordless_sudo="0"
    if [[ "$passwordless_sudo" == "1" ]]; then
        if [ "$(python_cmd)" == "python3" ]; then
            # possible bug in ansible, f29 python 3 env fails
            # w/o both python-libselinux packages installed
            # https://bugs.launchpad.net/tripleo/+bug/1812324
            PYTHON_PACKAGES+=("python3-libselinux python2-libselinux")
            PYTHON_PACKAGES+=("python3-PyYAML")
            SETUPTOOLS_PACKAGE=python3-setuptools
            VIRTUALENV_PACKAGE=python3-virtualenv
            PIP_PACKAGE=python3-pip
        else
            PYTHON_PACKAGES+=("libselinux-python")
            SETUPTOOLS_PACKAGE=python-setuptools
            VIRTUALENV_PACKAGE=python-virtualenv
            PIP_PACKAGE=python-pip
        fi

        check_python_module virtualenv &> /dev/null || \
            PYTHON_PACKAGES+=($VIRTUALENV_PACKAGE)

        check_python_module setuptools &> /dev/null || \
            PYTHON_PACKAGES+=($SETUPTOOLS_PACKAGE)

        sudo $(package_manager) install -y \
            /usr/bin/git \
            gcc \
            iproute \
            libyaml \
            libffi-devel \
            openssl-devel \
            redhat-rpm-config \
            ${PYTHON_PACKAGES[@]}
    else
        echo "WARNING: SUDO is not passwordless, assuming all packages are installed!"
    fi

    # pip is a special case because centos-7 repos do not have an rpm for
    # it but EPEL or OSP repos do, so we attempt to install the rpm and
    # fallback to easy_install before failing
    check_python_module pip &> /dev/null || {
        if yum provides pip 2>&1 | grep 'No matches found' >/dev/null; then
            sudo easy_install pip
        else
            sudo $(package_manager) install -y $PIP_PACKAGE
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
        echo "install-deps succeeded."
    fi
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && install_deps
