#!/bin/bash
# Get a CI node

set -eux

function usage {
    echo "get-node.sh args"
    echo ""
    echo "./get-node.sh"
    echo "-h --help"
    echo "-r --centos-release=$CENTOS_RELEASE ( defaults to $CENTOS_RELEASE)"
    echo ""
}

# set a reasonable default
CENTOS_RELEASE=7

PARAMS=""
while (( "$#" )); do
    case "$1" in
        -r|--centos-release)
            # default centos-7
            CENTOS_RELEASE=${2:-$CENTOS_RELEASE}
            shift 2
            ;;
        --) # end argument parsing
            shift
            break
            ;;
        -h|--help)
            usage
            break
            ;;
        -*|--*=) # unsupported flags
            echo "Error: Unsupported flag $1" >&2
            usage
            exit 1
            ;;
        *) # preserve positional arguments
            PARAMS="$PARAMS $1"
            shift
            ;;
    esac
done
# set positional arguments in their proper place
eval set -- "$PARAMS"

pushd $WORKSPACE/tripleo-quickstart
# (trown) Use quickstart.sh to set up the environment.
# This serves as a fail-fast syntax check for quickstart gates.
./quickstart.sh \
    --working-dir $WORKSPACE/ \
    --no-clone \
    --bootstrap \
    --requirements requirements.txt \
    --requirements quickstart-extras-requirements.txt \
    --requirements ci-scripts/ci-base-requirements.txt \
    --playbook noop.yml \
    127.0.0.2
popd

$WORKSPACE/bin/cico inventory --all

$WORKSPACE/bin/cico node get \
    --arch x86_64 \
    --release $CENTOS_RELEASE \
    --count 1 \
    --retry-count 15 \
    --retry-interval 60 \
    -f csv | sed "1d" > $WORKSPACE/provisioned.csv

$WORKSPACE/bin/cico inventory --all
if [ -s $WORKSPACE/provisioned.csv ]; then
    cat $WORKSPACE/provisioned.csv
else
    echo "FATAL: no nodes were provisioned"
    exit 1
fi

export VIRTHOST=`cat provisioned.csv | tail -1 | cut -d "," -f 3| sed -e 's/"//g'`
export VIRTHOST_KEY=`cat provisioned.csv | tail -1 | cut -d "," -f 7| sed -e 's/"//g'`
echo $VIRTHOST > $WORKSPACE/virthost
echo $VIRTHOST_KEY > $WORKSPACE/cico_key.txt
