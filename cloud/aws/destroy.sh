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
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" 2>&1 > /dev/null && pwd )"
source $DIR/../../config/aws/cloud.env
. $DIR/login.sh # Make sure we are logged in
source ~/.aws/mfa


# Delete the volume mount points and targets
EFS_VOL_ID=$(aws efs describe-file-systems --creation-token "demo-volume" --query "FileSystems[*].FileSystemId" | jq -r '.[]' | tr -s '\n' ',' | sed 's/,$//')
if [ ! -z $EFS_VOL_ID ]
then
    aws efs describe-mount-targets \
    --file-system-id ${EFS_VOL_ID} \
    | jq -r '.MountTargets[]' \
    | jq -r '.MountTargetId' \
    | while IFS= read -r target_id; do
        aws efs delete-mount-target --mount-target-id ${target_id}
    done
    
    EC2_SEC_RES=$(aws ec2 describe-security-groups --filters Name=group-name,Values=${CLUSTER_TARGET} --query "SecurityGroups[*].{VPC:VpcId,ID:GroupId}" | jq -r '.[]')
    if [ ! -z $(echo ${EC2_SEC_RES} | jq -r '.ID' 2> /dev/null)]
    then
        aws ec2 delete-security-group --group-id $(echo ${EC2_SEC_RES} | jq -r '.ID')
    fi
    
    
    # Remove the file system volume
    aws efs delete-file-system --file-system-id ${EFS_VOL_ID}
fi

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
