#!/bin/bash
# -----------------------------------------------------------------------------
set -euo pipefail # Stop running the script on first error...
# -----------------------------------------------------------------------------
# Register an Amazon AWS account for free:
#  - https://aws.amazon.com/
# See also:
#  - https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html
#  - https://eksctl.io/introduction/#installation
#  - https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html
# -----------------------------------------------------------------------------
# Load env vars from file `../aws/cloud.env`
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null 2>&1 && pwd )"
CFG="$( cd $DIR/../../config/ && pwd )/aws"
source $CFG/cloud.env

# Define new deployment settings
echo "" > $CFG/deploy.ini


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
echo "base.repo=$REGISTRY" >> $CFG/deploy.ini


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
    
    # Scale to [n] nodes if needed
    NODE_GROUP=$(eksctl get nodegroup --cluster=${CLUSTER_TARGET} -o=json | jq -r '.[].Name')
    eksctl scale nodegroup --cluster=${CLUSTER_TARGET} --nodes=1 --name=${NODE_GROUP}
fi

EKS_VPC_ID=$(aws eks describe-cluster --name ${CLUSTER_TARGET} --query "cluster.resourcesVpcConfig.vpcId" --output text)
EKS_VPC_CIDR=$(aws ec2 describe-vpcs --vpc-ids ${EKS_VPC_ID} --query "Vpcs[].CidrBlock" --output text)
echo "meta.vpcid=${EKS_VPC_ID}" >> $CFG/deploy.ini
echo "meta.cidrs=${EKS_VPC_CIDR}" >> $CFG/deploy.ini



# Add Security group for EKS and FS
EC2_SEC_RES=$(aws ec2 describe-security-groups --filters Name=group-name,Values=${CLUSTER_TARGET} Name=vpc-id,Values=${EKS_VPC_ID} --query "SecurityGroups[*].{Name:GroupName,ID:GroupId}" | jq -r '.[]')
EC2_SEC_KEY=$(echo ${EC2_SEC_RES} | jq .ID 2> /dev/null)
if [ -z $EC2_SEC_KEY ]
then    
    echo "Creating a new security group for '${CLUSTER_TARGET}' using VPC '${EKS_VPC_ID}'..."
    EC2_SEC_GRP=$(aws ec2 create-security-group --description "Allow EKS access to FS" --group-name ${CLUSTER_TARGET} --vpc-id ${EKS_VPC_ID} | jq -r '.GroupId')
else
    EC2_SEC_GRP=$(echo ${EC2_SEC_RES} | jq -r '.ID')
    echo "Using security group: ${EC2_SEC_RES}"
fi
echo "meta.sec_group.name=${EC2_SEC_GRP}" >> $CFG/deploy.ini


# Enable the NFS ingress traffic for the the VPC (if its not enabled)
if ! aws ec2 describe-security-groups --filters Name=group-name,Values=${CLUSTER_TARGET} Name=vpc-id,Values=${EKS_VPC_ID} \
| jq -r '.SecurityGroups[]' \
| jq -r '.IpPermissions[]' \
| jq -r '.FromPort' \
| grep 2049 2>&1 >/dev/null
then
    aws ec2 authorize-security-group-ingress \
    --group-id ${EC2_SEC_GRP} \
    --protocol tcp \
    --port 2049 \
    --cidr ${EKS_VPC_CIDR}
fi


# Create the filesystem and store the volume id
EFS_CURRENT_FS=$(aws efs describe-file-systems --creation-token "${VOLUME_NAME}" | jq -r '.FileSystems[]' 2>/dev/null)
if [ "${EFS_CURRENT_FS:-}" = "" ]
then
    echo "Creating new filesystem with token: ${VOLUME_NAME}"
    aws efs create-file-system --creation-token "${VOLUME_NAME}"
fi
EFS_VOL_ID=$(aws efs describe-file-systems --creation-token "${VOLUME_NAME}" --query "FileSystems[*].FileSystemId" | jq -r '.[]' | tr -s '\n' ',' | sed 's/,$//')
echo "storage.volume.csi.volumeHandle=${EFS_VOL_ID}" >> $CFG/deploy.ini


# Add mount points to each subnet
EFS_MOUNT_TARGETS=$(aws efs describe-mount-targets --file-system-id ${EFS_VOL_ID} | jq -r '.MountTargets[]' | jq -r '.SubnetId' 2>/dev/null)
if [ "${EFS_MOUNT_TARGETS:-}" = "" ]
then
    # https://aws.amazon.com/premiumsupport/knowledge-center/eks-persistent-storage/
    aws eks describe-cluster --name ${CLUSTER_TARGET} --query "cluster.resourcesVpcConfig" \
    | jq -r '.subnetIds[]' \
    | while IFS= read -r subnet; do
        aws efs create-mount-target \
        --file-system-id ${EFS_VOL_ID} \
        --security-groups ${EC2_SEC_GRP} \
        --subnet-id ${subnet} \
        | jq -r '.SubnetId'
    done
    
fi

kubectl get nodes

