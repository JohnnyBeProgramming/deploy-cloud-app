#!/bin/bash
# -----------------------------------------------------------------------------
set -euo pipefail # Stop running the script on first error...
# -----------------------------------------------------------------------------
# Install docker for desktop:
#  - https://www.docker.com/products/docker-desktop
# -----------------------------------------------------------------------------
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/../../config/local/cloud.env

# Initialise tooling and local kubernetes cluster
#  -> https://www.techrepublic.com/article/how-to-add-kubernetes-support-to-docker-desktop/


# In local mode, we will not create any image repositories
# -> No image registry needed for local.


# In local mode, no need to define any storage
# -> No storage resources needed for local.


# Make sure we are configured to point to the correct cluster
kubectl config use-context docker-desktop


# Docker for desktop is a single node cluster. 
# -> Cannot scale to more than one...


kubectl get nodes