#!/bin/bash
# -----------------------------------------------------------------------------
set -euo pipefail # Stop running the script on first error...
# -----------------------------------------------------------------------------
# Install docker for desktop:
#  - https://www.docker.com/products/docker-desktop
# -----------------------------------------------------------------------------
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/../../config/local/cloud.env


# No cluster and/or image repository to delete
echo "Noting to delete"