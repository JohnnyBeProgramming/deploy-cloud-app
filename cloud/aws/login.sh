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

