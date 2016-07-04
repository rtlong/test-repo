#!/bin/bash

# Developer-oriented environment setup script
# -------------------------------------------
#
# Source this in your shell for the correct environment variables
#
# If you add a variable here, please check if it's set already and ignore it in that case

export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-platform}"

# set up DOCKER_HOST automatically using docker-machine, if a DOCKER_MACHINE_NAME has been set
if [[ ${DOCKER_MACHINE_NAME:-} ]] && command -v docker-machine > /dev/null; then
  eval $(docker-machine env "${DOCKER_MACHINE_NAME}")
fi

export PATH="${PWD}/devtools/bin:$PATH"

export DEV_MODE='true'

export DEVTOOL_IMAGE_REPO="${DEVTOOL_IMAGE_REPO:-quay.io/goodguide/platform-devtool}"
export DEVTOOL_IMAGE_TAG="${DEVTOOL_IMAGE_TAG:-v3}"

export DEVTOOL_DOCKER="${DEVTOOL_DOCKER:-y}"
