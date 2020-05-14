#!/bin/bash
# -----------------------------------------------------------------------------
set -euo pipefail # Stop running the script on first error...
# -----------------------------------------------------------------------------
# Register an Azure account for free:
#  - http://azure.microsoft.com/
# -----------------------------------------------------------------------------
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/../../config/azure/cloud.env


# Login to Azure account
az --version
az login

# Delete the AKS Cluster 
az aks delete -n ${CLUSTER_TARGET} -g ${CLUSTER_TARGET}

# Delete the ACR Image Repository
az acr repository delete -n ${CLUSTER_TARGET} --repository ${ARTIFACT}

# Delete the entire resource group
az group delete -n ${CLUSTER_TARGET}