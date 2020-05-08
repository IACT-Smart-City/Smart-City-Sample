#!/bin/bash -e

DIR=$(dirname $(readlink -f "$0"))
SCENARIO="${2:-traffic}"
NOFFICES="${4:-1}"

shift
. "$DIR/build.sh"

function create_and_deploy_office_db_key_pair {
    # create key pair for ssh to cloud db host machine
    rm -rf ${DIR}/relay-key-pair
    mkdir ${DIR}/relay-key-pair
    ssh-keygen -f ${DIR}/relay-key-pair/relay-key -q -N ""

    # copy keys to cloud db host machine
    echo ""
    echo "-----------------------------------------------------------------------------------------------"
    echo "To copy key pair to remote cloud db host"
    echo "ssh-copy-id -i ${DIR}/relay-key-pair/relay-key -o StrictHostKeyChecking=no $CLOUD_HOST"
    ssh-copy-id -i ${DIR}/relay-key-pair/relay-key -o StrictHostKeyChecking=no root@$CLOUD_HOST
    echo "-----------------------------------------------------------------------------------------------"

    kubectl create secret generic relay-key-pair-secret --from-file=${DIR}/relay-key-pair/relay-key --from-file=${DIR}/relay-key-pair/relay-key.pub
}

if [[ -z $CLOUD_HOST ]]; then
  echo "Please define environment variable CLOUD_HOST"
  exit 0
fi

if [[ -z $CAMERA_HOSTS ]]; then
  echo "Please define environment variable CAMERA_HOSTS"
  exit 0
fi


# create configmap
kubectl create configmap sensor-info "--from-file=${DIR}/../../../maintenance/db-init/sensor-info.json"

create_and_deploy_office_db_key_pair

for yaml in $(find "$DIR" -maxdepth 1 -name "*.yaml" -print); do
    kubectl apply -f "$yaml"
done
