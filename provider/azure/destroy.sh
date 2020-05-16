#!/bin/bash
# -----------------------------------------------------------------------------
set -euo pipefail # Stop running the script on first error...
# -----------------------------------------------------------------------------
# Register an Azure account for free:
#  - http://azure.microsoft.com/
# -----------------------------------------------------------------------------
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" 2>&1 > /dev/null && pwd )"
source $DIR/../../config/azure/cloud.env


# Login to Azure account
az --version
az login


# Delete the AKS Cluster
if az aks show -n ${CLUSTER_TARGET} -g ${CLUSTER_TARGET} > /dev/null 2>&1
then
    az aks delete -n ${CLUSTER_TARGET} -g ${CLUSTER_TARGET}
fi


# Delete the ACR Image Repository
if az acr repository show -n ${CLUSTER_TARGET} --repository ${ARTIFACT} > /dev/null 
then
    az acr repository delete -n ${CLUSTER_TARGET} --repository ${ARTIFACT}
fi
# az acr delete -n ${CLUSTER_TARGET} --resource-group ${CLUSTER_TARGET}


# Delete the Azure Disk
if az disk show --resource-group ${CLUSTER_TARGET} --name demo-volume > /dev/null 2>&1
then
    az disk delete \
    --resource-group ${CLUSTER_TARGET} \
    --name demo-volume
fi


# Delete the entire resource group
if az group show -n ${CLUSTER_TARGET} > /dev/null 2>&1
then
    az group delete -n ${CLUSTER_TARGET}
fi


# Remove the deployment config
check_file="$DIR/../../config/azure/deploy.ini"
[ -f $check_file ] && rm -f $check_file
