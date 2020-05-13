#!/bin/bash
# -----------------------------------------------------------------------------
set -euo pipefail # Stop running the script on first error...
# -----------------------------------------------------------------------------
# Register an Google Cloud account for free:
#  - http://cloud.google.com/
s# -----------------------------------------------------------------------------
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/../../config/google/cloud.env



# Delete the GKE Cluster
if gcloud container clusters list --region ${CLUSTER_REGION} | grep ${CLUSTER_TARGET} 2>&1 > /dev/null
then
    gcloud container clusters delete ${CLUSTER_TARGET} --region ${CLUSTER_REGION}
fi

# Delete the container Image Repository
#gcloud container images list --filter="${REGISTRY}" --format json \
#| jq -r '.[].name' \
#| xargs -0 gcloud container images list-tags gcr.io/johnny-demo-cluster/demo --format json
#gcloud container images delete ${REGISTRY}/${IMAGE_ID}


# Delete the entire project
gcloud projects delete ${GOOGLE_PROJECT}