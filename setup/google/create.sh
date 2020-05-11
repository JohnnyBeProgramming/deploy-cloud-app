#!/bin/bash
# -----------------------------------------------------------------------------
set -euo pipefail # Stop running the script on first error...
# -----------------------------------------------------------------------------
# Register an Azure account for free:
#  - http://azure.microsoft.com/
# -----------------------------------------------------------------------------
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/../../config/google.env


# Login to Google account


# Create an image registry to store docker containers


# Login to container registry


# Create a new GKE Cluster (single node)

# Configure local kubectl to connect to our AKS cluster


# Scale to [n] nodes if needed



kubectl get nodes