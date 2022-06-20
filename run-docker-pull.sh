#!/bin/bash

[ "${DEBUG}" == true ] && set -x

THREAD=${1:-standalone}

logger () {
    echo "[Thread ${THREAD}] ${1}"
}

ERROR=false
DOCKER_REGISTRY=${DOCKER_REGISTRY?Must set DOCKER_REGISTRY}
DOCKER_USER=${DOCKER_USER:-admin}
DOCKER_PASSWORD=${DOCKER_PASSWORD:-password}

while read -r a b c d; do 
   containerNames+=($a)
done < uploaded-container-names.csv

# echo ${containerNames[@]}


#Pull a random docker image from the above list

randomIndex=$(( $RANDOM % ${#containerNames[@]} ))
CMD="docker pull ${DOCKER_REGISTRY}/${containerNames[randomIndex]}"
${CMD} > /dev/null 2>&1 || ERROR=true
if [ "${ERROR}" == true ]; then
    logger "ERROR: ${CMD} failed"
    exit 1
fi
