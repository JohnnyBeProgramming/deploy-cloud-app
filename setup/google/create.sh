#!/bin/bash
# -----------------------------------------------------------------------------
set -euo pipefail # Stop running the script on first error...
# -----------------------------------------------------------------------------
# Register an Google Cloud account for free:
#  - http://cloud.google.com/
# -----------------------------------------------------------------------------
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/../../config/google.env

# Initialise tooling
# curl https://sdk.cloud.google.com | bash


# Login to Google account and set up project
if gcloud projects list | grep ${GCP_PROJECT} 2>&1 > /dev/null
then
    echo "Project already exists"
    gcloud projects list --format json \
    | jq -c "map(select(.projectId | contains(\"${GCP_PROJECT}\")) )" \
    | jq -r '.[]'
else
    gcloud projects create ${GCP_PROJECT}
fi
gcloud init --project ${GCP_PROJECT}


# Initialise gcr.io container registry (if not already registered)
if cat ~/.docker/config.json | jq .credHelpers | grep gcr.io 2>&1 > /dev/null
then
    echo "Registry found: gcr.io"
else
    gcloud auth configure-docker
fi


# Create a new GKE Cluster (2 nodes) if not exists
if gcloud container clusters list --region ${GCP_REGION} | grep ${GKE_TARGET} 2>&1 > /dev/null
then
  echo "Cluster found: ${GKE_TARGET}"
else
  gcloud container clusters create ${GKE_TARGET} --region ${GCP_REGION} --num-nodes 2
fi


# Scale to [n] nodes if needed
gcloud container clusters resize ${GKE_TARGET} --region ${GCP_REGION} --num-nodes 1


kubectl get nodes