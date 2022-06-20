#!/bin/bash

THREAD=${1:-standalone}

logger () {
    echo "[Thread ${THREAD}] ${1}"
}

ERROR=false
DOCKER_REGISTRY=${DOCKER_REGISTRY?Must set DOCKER_REGISTRY}
DOCKER_USER=${DOCKER_USER:-admin}
DOCKER_PASSWORD=${DOCKER_PASSWORD:-password}

while read -r a ; do 
   containerNames+=($a)
done < uploaded-container-names.csv

# echo ${containerNames[@]}

docker login -u ${DOCKER_USER} -p ${DOCKER_PASSWORD} ${DOCKER_REGISTRY} || exit 1

#Pull a random docker image from the above list

randomIndex=$(( $RANDOM % ${#containerNames[@]} ))
CMD="docker pull ${DOCKER_REGISTRY}/${containerNames[randomIndex]}:1"

${CMD} >>stdout 2>>stderr || ERROR=true

if [ "${ERROR}" == true ]; then
    logger "ERROR: ${CMD} failed"
    exit 1
fi
