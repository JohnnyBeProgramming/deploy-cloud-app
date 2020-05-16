#!/bin/bash
# -----------------------------------------------------------------------------
set -euo pipefail # Stop running the script on first error...
# -----------------------------------------------------------------------------
# Register an Google Cloud account for free:
#  - http://cloud.google.com/
# -----------------------------------------------------------------------------
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" 2>&1 >/dev/null && pwd )"
CFG="$( cd $DIR/../../config/ && pwd )/google"
source $CFG/cloud.env

# Define new deployment settings
echo "" > $CFG/deploy.ini

# Initialise tooling
# curl https://sdk.cloud.google.com | bash


# Login to Google account and set up project
if gcloud projects list | grep ${GOOGLE_PROJECT} 2>&1 > /dev/null
then
    echo "Project already exists"
    gcloud projects list --format json \
    | jq -c "map(select(.projectId | contains(\"${GOOGLE_PROJECT}\")) )" \
    | jq -r '.[]'
else
    gcloud projects create ${GOOGLE_PROJECT}
fi
gcloud init --project ${GOOGLE_PROJECT}

# Enable and link the billing account to this project (required for GKE service)
gcloud services enable cloudbilling.googleapis.com
gcloud beta billing projects link ${GOOGLE_PROJECT} --format=json \
--billing-account=$(gcloud beta billing accounts list --format json | jq -r '.[].name' | sed s/billingAccounts\\///) \
| jq .

# Enable all other required services for this project
gcloud services enable storage-component.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com


# Define some storage resources to be used by our cluster
if gcloud compute disks describe "demo-volume" --region ${CLUSTER_REGION} 2>&1 > /dev/null
then
  echo "Drive 'demo-volume' already exists"
else
  gcloud compute disks create "demo-volume" \
  --region ${CLUSTER_REGION} \
  --replica-zones $(gcloud compute zones list | grep ${CLUSTER_REGION} | cut -d ' ' -f 1 | head -n 2 | paste -sd "," -) \
  --size "10GB" \
  --type "pd-ssd"
fi

# Initialise gcr.io container registry (if not already registered)
if cat ~/.docker/config.json | jq .credHelpers | grep gcr.io 2>&1 > /dev/null
then
    echo "Registry found: gcr.io"
else
    gcloud auth configure-docker
fi


# Create a new GKE Cluster (2 nodes) if not exists
if gcloud container clusters list --region ${CLUSTER_REGION} | grep ${CLUSTER_TARGET} 2>&1 > /dev/null
then
    echo "Cluster found: ${CLUSTER_TARGET}"
else
    gcloud container clusters create ${CLUSTER_TARGET} --region ${CLUSTER_REGION} --num-nodes 2
fi


# Scale to [n] nodes if needed
gcloud container clusters resize ${CLUSTER_TARGET} --region ${CLUSTER_REGION} --num-nodes 1


kubectl get nodes