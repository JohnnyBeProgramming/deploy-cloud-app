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


# Remove the deployment config
check_file="$DIR/../../config/local/deploy.ini"
[ -f $check_file ] && rm -f $check_file
