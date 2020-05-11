#!/bin/bash
# -----------------------------------------------------------------------------
set -euo pipefail # Stop running the script on first error...
# -----------------------------------------------------------------------------
# Register an Azure account for free:
#  - http://azure.microsoft.com/
# -----------------------------------------------------------------------------
AZ_LOCATION="westeurope"
AZ_RESOURCE="kube-demo"
AKS_TARGET="azurejohnny"
ACR_TARGET="azurejohnny"

# Login to Azure account
az --version
az login

# Delete the AKS Cluster 
az aks delete -n ${AKS_TARGET} -g ${AZ_RESOURCE}

# Delete the ACR Image Repository
az acr repository delete -n ${ACR_TARGET} --repository "demo/demo-app"

# Delete the entire resource group
az group delete -n ${AZ_RESOURCE}