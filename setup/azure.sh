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

# Install required providers from microsoft
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.OperationsManagement

# List and select an account
az account list | jq -r ".[] | .name"
az account set --subscription "Free Trial"

# List and select a default region
az account list-locations | jq -r ".[] | .name"

# Create our resource group where we will deploy our app
az group create --name ${AZ_RESOURCE} --location ${AZ_LOCATION}

# Create an Azure ACR registry to store docker containers
az acr create \
    --location ${AZ_LOCATION} \
    --resource-group ${AZ_RESOURCE} \
    --name ${ACR_TARGET} \
    --sku "Basic" \
  | jq .provisioningState

# Login to ACR registry
az acr login --name ${ACR_TARGET}

# Create a new AKS Cluster (single node)
az aks create \
    --name ${AKS_TARGET} \
    --resource-group ${AZ_RESOURCE} \
    --node-vm-size="Standard_A4m_v2" \
    --node-count 1 \
 | jq .provisioningState

# Assign a role to allow image pulls from our new cluster
az role assignment create \
    --assignee $(az aks show --query servicePrincipalProfile.clientId -n ${AKS_TARGET} -g ${AZ_RESOURCE} -o tsv) \
    --scope $(az acr show --query id -n ${ACR_TARGET} -g ${AZ_RESOURCE} -o tsv) \
    --role "acrpull" \
 | jq .scope

# Enable monitoring on the cluster
az aks enable-addons -a monitoring --name ${AKS_TARGET} --resource-group ${AZ_RESOURCE} | jq .fqdn || true

# Configure local kubectl to connect to our AKS cluster
az aks get-credentials --name ${AKS_TARGET} --resource-group ${AZ_RESOURCE}

# Test connection to the AKS CLuster using kubectl
kubectl get nodes

# Scale to [n] nodes
az aks scale -c 1 -g ${AZ_RESOURCE} -n ${AKS_TARGET} | jq .fqdn
kubectl get nodes