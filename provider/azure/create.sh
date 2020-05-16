#!/bin/bash
# -----------------------------------------------------------------------------
set -euo pipefail # Stop running the script on first error...
# -----------------------------------------------------------------------------
# Register an Azure account for free:
#  - http://azure.microsoft.com/
# -----------------------------------------------------------------------------
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CFG="$( cd $DIR/../../config/ && pwd )/azure"
source $CFG/cloud.env

# Define new deployment settings
echo "" > $CFG/deploy.ini

# Login to Azure account
# az --version
az login

# Install required providers from microsoft
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.OperationsManagement

# List and select an account
# az account list | jq -r ".[] | .name"
az account set --subscription "${CLUSTER_SUBSCRIPTION}"

# List and select a default region
# az account list-locations | jq -r ".[] | .name"

# Create our resource group where we will deploy our app
az group create --name ${CLUSTER_TARGET} --location ${CLUSTER_REGION} \
| jq .properties.provisioningState

# Provision a disk for our cluster
az disk create \
--resource-group ${CLUSTER_TARGET} \
--name "demo-volume" \
--sku "Standard_LRS" \
--os-type "Linux" \
--size-gb 10 \
| jq .provisioningState

# Create an Azure ACR registry to store docker containers
az acr create \
--location ${CLUSTER_REGION} \
--resource-group ${CLUSTER_TARGET} \
--name ${CLUSTER_TARGET} \
--sku "Basic" \
| jq .provisioningState

# Login to ACR registry
az acr login --name ${CLUSTER_TARGET}

# Create a new AKS Cluster (single node)
az aks create \
--name ${CLUSTER_TARGET} \
--resource-group ${CLUSTER_TARGET} \
--node-vm-size="Standard_A4m_v2" \
--node-count 1 \
| jq .provisioningState

# Assign a role to allow image pulls from ACR to our new cluster
assignee=$(az aks show --query servicePrincipalProfile.clientId -n ${CLUSTER_TARGET} -g ${CLUSTER_TARGET} -o tsv)
scope=$(az acr show --query id -n ${CLUSTER_TARGET} -g ${CLUSTER_TARGET} -o tsv)
az role assignment create --assignee $assignee --scope $scope --role "acrpull" | jq .scope

# Assign a role for the cluster to access the storage resource
assignee=$(az aks show --query servicePrincipalProfile.clientId -n ${CLUSTER_TARGET} -g ${CLUSTER_TARGET} -o tsv)
scope=$(az disk show --resource-group ${CLUSTER_TARGET} --name "demo-volume" --query id -o tsv)
az role assignment create --assignee $assignee --scope $scope --role Contributor | jq .scope
echo "storage.volume.azureDisk.diskURI=$scope" >> $CFG/deploy.ini


# Enable monitoring on the cluster
# az aks enable-addons -a monitoring --name ${CLUSTER_TARGET} --resource-group ${CLUSTER_TARGET} | jq .fqdn || true

# Configure local kubectl to connect to our AKS cluster
az aks get-credentials --name ${CLUSTER_TARGET} --resource-group ${CLUSTER_TARGET}

# Scale to [n] nodes if needed
az aks scale -c 1 -g ${CLUSTER_TARGET} -n ${CLUSTER_TARGET} | jq .fqdn
kubectl get nodes