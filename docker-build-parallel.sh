#!/bin/bash

[ "${DEBUG}" == true ] && set -x

terminate () {
    echo -e "\nTerminating..."
    exit 1
}

# Catch Ctrl+C and other termination signals to shutdown
trap terminate SIGINT SIGTERM SIGHUP

START_TIME=$(date +'%s')

export NUMBER_OF_IMAGES=${NUMBER_OF_IMAGES:-1}
export NUMBER_OF_LAYERS=${NUMBER_OF_LAYERS:-1}
export SIZE_OF_LAYER_KB=${SIZE_OF_LAYER_KB:-1}
export NUM_OF_THREADS=${NUM_OF_THREADS:-1}
export DOCKER_REGISTRY=${DOCKER_REGISTRY?Must set DOCKER_REGISTRY}
export OWNER=${OWNER:-docker-auto}
export REMOVE_IMAGES=${REMOVE_IMAGES:-true}
export TAG=${TAG:-1}


echo "== Creating ${NUMBER_OF_IMAGES} Docker images"
echo "== Images with ${NUMBER_OF_LAYERS} layers"
echo "== Layers size ${SIZE_OF_LAYER_KB} KB"
echo "== Using ${NUM_OF_THREADS} threads"
echo

# Calculate the loop size
LOOP_SIZE=$(( ${NUMBER_OF_IMAGES} / ${NUM_OF_THREADS} ))
LOOP_REMAINDER=$(( ${NUMBER_OF_IMAGES} % ${NUM_OF_THREADS} ))

echo "LOOP_SIZE is ${LOOP_SIZE}"
echo "LOOP_REMAINDER is ${LOOP_REMAINDER}"

# Create the Docker images
if [ ${LOOP_SIZE} -gt 0 ]; then
    for a in $(seq 1 ${LOOP_SIZE}); do

        # Call the docker build script
        echo -e "\n\n[${a}/${LOOP_SIZE}] Preparing batch of ${NUM_OF_THREADS} images"
        for b in $(seq 1 ${NUM_OF_THREADS}); do
            ./run-docker-build.sh ${b} &
        done

        # Wait for all background processes to finish
        wait
    done
fi

# Do the remainder threads if needed
if [ ${LOOP_REMAINDER} -gt 0 ]; then
    echo -e "\n\n[Remainder (last batch)] Preparing batch of ${LOOP_REMAINDER} images"
    for b in $(seq 1 ${NUMBER_OF_IMAGES}); do
        ./run-docker-build.sh ${b}
    done
fi

# Wait for all background processes to finish
wait

END_TIME=$(date +'%s')
ELAPSED_TIME=$(( ${END_TIME} - ${START_TIME} ))

echo -e "\nCompleted in ${ELAPSED_TIME} seconds"
