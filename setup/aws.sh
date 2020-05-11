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
source $DIR/../aws.env


# Install required cli tools
aws --version
aws-iam-authenticator version
eksctl version

# Test connection
if aws sts get-caller-identity > /dev/null
then
    # Already logged in
    echo $(aws sts get-caller-identity | jq .Arn)
else
    # Login to AWS account
    aws configure
    
    echo "Please enter your mfa code:"
    read mfa_code
    arn=`aws iam get-user | jq '.User.Arn' | sed s/user/mfa/ | sed s/\"//g`
    json=`aws sts get-session-token --serial-number $arn --token-code $mfa_code`
    echo "
export AWS_ACCESS_KEY_ID=$(echo $json | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo $json | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo $json | jq -r .Credentials.SessionToken)
    " > ~/.aws/mfa
    source ~/.aws/mfa
fi

# Login to AWS container registries
$(aws ecr get-login --region ${AWS_REGION} --no-include-email)


# Create an AWS ECR image repository to store a docker image (if it does not exists)
if aws ecr describe-repositories --repository-names ${ECR_TARGET} 2> /dev/null
then
    # The image repository already exists
    export AWS_REGISTRY=$(aws ecr describe-repositories --repository-names ${ECR_TARGET} 2> /dev/null | jq -r '.repositories[].repositoryUri' || echo '')
else
    # Create a new repository for this image
    export AWS_REGISTRY=$(aws ecr create-repository --repository-name ${ECR_TARGET} | jq .repository.repositoryUri)
fi


# Create a AWS EKS cluster if not exists
if aws eks describe-cluster --name ${EKS_TARGET} | jq .cluster.endpoint 2> /dev/null
then
    # The cluster was detected, skip...
    echo " - Check your kube context '$(kubectl config current-context)' is correct."
    echo " - Warning: Cluster '${EKS_TARGET}' already exists."
else
    # Create a new EKS Cluster (single node)
    eksctl create cluster \
    --name ${EKS_TARGET} \
    --region ${AWS_REGION} \
    --nodes 2 \
    --nodes-min 1 \
    --nodes-max 3
    # This will also switch your kubectl command to the new cluster
fi


# Scale to [n] nodes if needed
NODE_GROUP=$(eksctl get nodegroup --cluster=${EKS_TARGET} -o=json | jq -r '.[].Name')
eksctl scale nodegroup --cluster=${EKS_TARGET} --nodes=1 --name=${NODE_GROUP}

kubectl get nodes