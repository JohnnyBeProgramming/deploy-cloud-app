#!/bin/bash
# -----------------------------------------------------------------------------
set -euo pipefail # Stop running the script on first error...
# -----------------------------------------------------------------------------
# Register an Amazon AWS account for free:
#  - https://aws.amazon.com/
# See also:
#  - https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html
#  - https://eksctl.io/introduction/#installation
# -----------------------------------------------------------------------------
# Load env vars from file `../aws.env`
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/../../config/aws.env
. $DIR/login.sh # Make sure we are logged in
source ~/.aws/mfa


# Create a AWS EKS cluster if not exists
FARGATE_TARGET=${CLUSTER_TARGET}-serverless
if aws eks describe-cluster --name ${FARGATE_TARGET} 2> /dev/null | jq .cluster.endpoint
then
    # The cluster was detected, skip...
    echo " - Check your kube context '$(kubectl config current-context)' is correct."
    echo " - Warning: Cluster '${FARGATE_TARGET}' already exists."
else
    # Create a new EKS Cluster (single node)
    eksctl create cluster \
    --name ${FARGATE_TARGET} \
    --region ${CLUSTER_REGION} \
    --fargate
    # This will also switch your kubectl command to the new cluster
fi

kubectl get nodes

