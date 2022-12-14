#!/bin/bash

# Build  a single Docker image

THREAD=${1:-standalone}

logger () {
    echo "  [Thread ${THREAD}] ${1}" 
}

# Create temp directory
GEN_DIR=$(mktemp -d)

NUMBER_OF_LAYERS=${NUMBER_OF_LAYERS:-1}
SIZE_OF_LAYER_KB=${SIZE_OF_LAYER_KB:-1}
DOCKER_REGISTRY=${DOCKER_REGISTRY?Must set DOCKER_REGISTRY}
# OWNER=${OWNER:-docker-auto}

# Generating random owner since there is namespace limit
OWNER=owner-$(openssl rand -hex 4)
DOCKER_USER=${DOCKER_USER:-admin}
DOCKER_PASSWORD=${DOCKER_PASSWORD:-password}
REMOVE_IMAGES=${REMOVE_IMAGES:-true}
TAG=${TAG:-1}
ERROR=false
# A common Id 
RID=$(openssl rand -hex 4)
GEN_ID=${DOCKER_GEN_ID:-$RID}


logger "==== Creating Docker image"

# echo "Docker login to ${DOCKER_REGISTRY}"
# docker login -u ${DOCKER_USER} -p ${DOCKER_PASSWORD} ${DOCKER_REGISTRY} || exit 1

# Build Docker image
image_name_prefix="generated-${NUMBER_OF_LAYERS}x${SIZE_OF_LAYER_KB}kb"
image_name=${image_name_prefix}-${GEN_ID}-$(openssl rand -hex 16)
logger "Image name: ${image_name}"

# Create Dockerfile
echo 'FROM scratch' > ${GEN_DIR}/Dockerfile

# Create the files for the images
for b in $(seq 1 ${NUMBER_OF_LAYERS}); do
    file_name=$(openssl rand -hex 16)
    CMD="dd if=/dev/urandom of=${GEN_DIR}/${file_name} bs=${SIZE_OF_LAYER_KB} count=1024"
    ${CMD} || ERROR=true
    
    if [ "${ERROR}" == true ]; then
        logger "ERROR: ${CMD} failed"
        exit 1
    fi
    
    file_size=$(ls -l ${GEN_DIR}/${file_name} | awk '{print $5}')
    logger "Created file ${file_name} (${file_size} bytes)"
    echo "COPY ${file_name} /files/" >> ${GEN_DIR}/Dockerfile
done

# Build Docker image
logger "Building image ${image_name}"
CMD="docker build -t ${DOCKER_REGISTRY}/${OWNER}/${image_name}:${TAG} ${GEN_DIR}/"

${CMD} || ERROR=true

if [ "${ERROR}" == true ]; then
    logger "ERROR: ${CMD} failed"
    exit 1
fi


# # Push image
logger "Pushing Docker image"
CMD="docker push ${DOCKER_REGISTRY}/${OWNER}/${image_name}:${TAG}"

${CMD}  || ERROR=true

if [ "${ERROR}" == true ]; then
    logger "ERROR: ${CMD} failed"
    exit 1
fi

# Cleanup
logger "Removing temp directory"
rm -rf ${GEN_DIR}

# logger "Removing Docker Image"
# docker rmi -f ${DOCKER_REGISTRY}/${OWNER}/${image_name} || ERROR=true

# if [ "${ERROR}" == true ]; then
#     logger "ERRORS found"
#     exit 1
# fi
logger "Completed"
