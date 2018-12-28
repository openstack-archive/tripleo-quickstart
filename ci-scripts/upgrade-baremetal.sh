#!/bin/bash
# CI test that does an upgrade of a full oooq deployment on baremetal.
# Use the major_upgrade flag to switch between major and minor upgrade
# $HW_ENV_DIR is the directory where environment-specific files are kept.
set -eux

RELEASE=$1
DELOREAN_HASH=$2
MAJOR_UPGRADE=$3
PACEMAKER=$4
TARGET_VERSION=$5
HW_ENV_DIR=$6
NETWORK_ISOLATION=$7
CONFIG=$8

# (trown) This is so that we ensure separate ssh sockets for
# concurrent jobs. Without this, two jobs running in parallel
# would try to use the same undercloud-stack socket.
socketdir=$(mktemp -d /tmp/sockXXXXXX)
export ANSIBLE_SSH_CONTROL_PATH=$socketdir/%%h-%%r

bash quickstart.sh \
    --extra-vars upgrade_delorean_hash=$DELOREAN_HASH \
    --extra-vars deployment_type=baremetal \
    --extra-vars major_upgrade=$MAJOR_UPGRADE \
    --extra-vars enable_pacemaker=$PACEMAKER \
    --extra-vars target_upgrade_version=$TARGET_VERSION \
    --extra-vars step_upgrade_overcloud=true \
    --extra-vars set_overcloud_workers=false \
    --working-dir $WORKSPACE/ \
    --no-clone \
    --bootstrap \
    --tags all \
    --teardown all \
    --config $WORKSPACE/$HW_ENV_DIR/network_configs/$NETWORK_ISOLATION/config_files/$CONFIG \
    --environment $WORKSPACE/$HW_ENV_DIR/network_configs/$NETWORK_ISOLATION/env_settings.yml \
    --playbook upgrade-baremetal.yml \
    --extra-vars undercloud_instackenv_template=$WORKSPACE/$HW_ENV_DIR/instackenv.json \
    --extra-vars network_environment_file=$WORKSPACE/$HW_ENV_DIR/network_configs/$NETWORK_ISOLATION/$NETWORK_ISOLATION.yml \
    --extra-vars nic_configs_dir=$WORKSPACE/$HW_ENV_DIR/network_configs/$NETWORK_ISOLATION/nic_configs/ \
    --release ${CI_ENV:+$CI_ENV/}$RELEASE${REL_TYPE:+-$REL_TYPE} \
    $VIRTHOST
