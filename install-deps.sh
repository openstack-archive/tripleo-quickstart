#!/bin/bash
# Formally part of quickstart.sh
# Now broken out for more reuse
# install-deps.sh

# atm mvp for the reproducer is python2 only
# expect this option to be removed once
# python2 and python3 have been validated

print_sudo_warning() {
    echo -e "\e[31m WARNING: SUDO is not passwordless, assuming all packages \
are installed! \n export USER_OVERRIDE_SUDO_CHECK=1 \n to be prompted for sudo \
password \e[0m"
}

python_cmd() {
    distribution=unknown
    distribution_major_version=unknown
    # we prefer python2 because on few systems python->python3
    python_cmd=${USER_PYTHON_OVERRIDE:=python2}

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        distribution_major_version=${VERSION_ID%.*}
        case $NAME in
        "Red Hat"*) distribution="RedHat"
            if [ "$distribution_major_version" -ge "8" ]; then
                python_cmd=${USER_PYTHON_OVERRIDE:=python3}
            fi
            ;;
        "CentOS"*)
            distribution="CentOS"
            if [ "$distribution_major_version" -ge "8" ]; then
                python_cmd=${USER_PYTHON_OVERRIDE:=python3}
            fi
            ;;
        "Fedora"*)
            distribution="Fedora"
            if [ "$distribution_major_version" -ge "28" ]; then
                python_cmd=${USER_PYTHON_OVERRIDE:=python3}
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

    # install enough rpms for the appropriate python version to
    # enable bindep and python environments

    echo "Running install_deps"
    PYTHON_PACKAGES=()
    MODULE_NAMES="pip virtualenv setuptools"
    rpm -q sudo || $(package_manager) install -y sudo
    sudo -n true && passwordless_sudo="1" || passwordless_sudo="0"
    if [[ "$passwordless_sudo" == "1" ]] || [ "$USER_OVERRIDE_SUDO_CHECK" == "1" ]; then
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
        echo "Installing RPM packages $PYTHON_PACKAGES $SETUPTOOLS_PACKAGE \
        $VIRTUALENV_PACKAGE $PIP_PACKAGE" | tr -s [:space:]
        sudo $(package_manager) -y install $PYTHON_PACKAGES \
                                            $SETUPTOOLS_PACKAGE \
                                            $VIRTUALENV_PACKAGE \
                                            $PIP_PACKAGE

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

copy_selinux_to_venv() {
    : ${LIBSELINUX_PYTHON_PATH:=lib64/python`$(python_cmd) -c "from sys import version_info as v; print('%s.%s' % (v[0], v[1]))"`/site-packages}

    for FILE in /usr/$LIBSELINUX_PYTHON_PATH/_selinux* /usr/$LIBSELINUX_PYTHON_PATH/selinux ; do
        ln -sf $FILE $VIRTUAL_ENV/$LIBSELINUX_PYTHON_PATH/
    done

    # validate that selinux import really works
    $(python_cmd) -c "import sys; print(sys.path); import selinux; print('selinux.is_selinux_enabled: %s' % selinux.is_selinux_enabled())"
}

install_virtual_env(){
    # Activate the virtualenv only when it is not already activated otherwise
    # It create the virtualenv and then activate it.

    echo "Running install_virtual_env"
    if [[ -z ${VIRTUAL_ENV+x} ]]; then
        $(python_cmd) -m virtualenv \
            $( [ "$OPT_SYSTEM_PACKAGES" = 1 ] && printf -- "--system-site-packages\n" )\
            $OPT_WORKDIR
        . $OPT_WORKDIR/bin/activate
    else
        echo "Warning: VIRTUAL_ENV=$VIRTUAL_ENV was found active and is being reused."
    fi
    $(python_cmd) -m pip install pip --upgrade
    echo "Installing bindep"
    $(python_cmd) -m pip install bindep --upgrade

    # In order to do any filesystem operations on the system running ansible (if it has SELinux installed)
    # we need the python bindings in the venv. Unfortunately, it is not available on pypi, so we need to
    # pull it from the system site packages. This is needed only if they are not already present there,
    # for example creating the virtualenv using --system-site-packages on a system that has the
    # libselinux python bidings does not need it, so we detect it first.
    $(python_cmd) -c "import selinux" 2>/dev/null ||
        copy_selinux_to_venv

}

install_bindep(){
    # --user installs fail from a virtenv
    echo "Running install_bindep"
    $(python_cmd) -m pip install --user bindep --upgrade
}

install_package_deps_via_bindep(){
    echo "install_package_deps_via_bindep"
    sudo -n true && passwordless_sudo="1" || passwordless_sudo="0"
    if [ "$passwordless_sudo" == "1" ] || [ "$USER_OVERRIDE_SUDO_CHECK" == "1" ]; then
        bindep -b || sudo $(package_manager) -y install `bindep -b`;
        # EPEL will NOT be installed on any nodepool nodes.
        # EPEL could be installed in the same transaction as other packages on CentOS/RHEL
        # This can leave the system with an older ansible version. Ansible 2.7+ required
        # Run through the deps and update them
        yum-config-manager enable epel || true
        sudo $(package_manager) -y update `bindep -b -l newline`
    else
        print_sudo_warning
    fi

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
        sudo $(package_manager) -y install $PACKAGES;
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

    # Allow to user to override the python version
    export USER_PYTHON_OVERRIDE=python2

    # This will allow the user to be prompted for commands
    # requiring sudo vs. skipping the install assuming the
    # requirements are already installed.
    export USER_OVERRIDE_SUDO_CHECK="1"

    # install just enough python
    install_deps
    # install bindep
    install_bindep
    # checks the $PWD for a file named
    # bindep_python[2,3].txt and installs
    # dependencies listed in the file.
    install_package_deps_via_bindep
fi
