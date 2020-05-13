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
# Load env vars from file `../aws/cloud.env`
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/../../config/aws/cloud.env
. $DIR/login.sh # Make sure we are logged in
source ~/.aws/mfa


# Login to AWS container registries
$(aws ecr get-login --region ${CLUSTER_REGION} --no-include-email)


# Create an AWS ECR image repository to store a docker image (if it does not exists)
if aws ecr describe-repositories --repository-names ${ARTIFACT} 2> /dev/null
then
    # The image repository already exists
    REGISTRY=$(aws ecr describe-repositories --repository-names ${ARTIFACT} 2> /dev/null | jq -r '.repositories[].repositoryUri' || echo '')
else
    # Create a new repository for this image
    REGISTRY=$(aws ecr create-repository --repository-name ${ARTIFACT} | jq .repository.repositoryUri)
fi


# Create a AWS EKS cluster if not exists
if aws eks describe-cluster --name ${CLUSTER_TARGET} 2> /dev/null | jq .cluster.endpoint 
then
    # The cluster was detected, skip...
    echo " - Check your kube context '$(kubectl config current-context)' is correct."
    echo " - Warning: Cluster '${CLUSTER_TARGET}' already exists."
else
    # Create a new EKS Cluster (single node)
    eksctl create cluster \
    --name ${CLUSTER_TARGET} \
    --region ${CLUSTER_REGION} \
    --nodes 2 \
    --nodes-min 1 \
    --nodes-max 3
    # This will also switch your kubectl command to the new cluster
fi


# Scale to [n] nodes if needed
NODE_GROUP=$(eksctl get nodegroup --cluster=${CLUSTER_TARGET} -o=json | jq -r '.[].Name')
eksctl scale nodegroup --cluster=${CLUSTER_TARGET} --nodes=1 --name=${NODE_GROUP}

kubectl get nodes

