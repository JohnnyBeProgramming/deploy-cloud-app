#!/bin/bash
# -----------------------------------------------------------------------------
set -euo pipefail # Stop running the script on first error...
# -----------------------------------------------------------------------------
# Register an Azure account for free:
#  - http://azure.microsoft.com/
# -----------------------------------------------------------------------------
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/../../config/azure.env


# Login to Azure account
az --version
az login

# Delete the AKS Cluster 
az aks delete -n ${AKS_TARGET} -g ${AZ_RESOURCE}

# Delete the ACR Image Repository
az acr repository delete -n ${ACR_TARGET} --repository "demo/demo-app"

# Delete the entire resource group
az group delete -n ${AZ_RESOURCE}