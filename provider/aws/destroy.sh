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


# Delete a AWS EKS cluster if exists
if aws eks describe-cluster --name ${CLUSTER_TARGET} 2> /dev/null | jq .cluster.endpoint
then
    eksctl delete cluster \
    --name ${CLUSTER_TARGET} \
    --region ${CLUSTER_REGION}
fi


# Create an AWS ECR image repository to store a docker image (if it does not exists)
if aws ecr describe-repositories --repository-names ${ARTIFACT} 2> /dev/null | jq -r '.repositories[].repositoryUri'
then
    aws ecr delete-repository --repository-name ${ARTIFACT} --force | jq -r '.repositories[].repositoryUri'
fi

# Remove the deployment config
check_file="$DIR/../../config/aws/deploy.ini"
[ -f $check_file ] && rm -f $check_file


# Make sure that the kube context was unset
kubectl config current-context || true
