#!/bin/bash
# -----------------------------------------------------------------------------
set -euo pipefail # Stop running the script on first error...
# -----------------------------------------------------------------------------
# Set up a cluster according to the environment
# -----------------------------------------------------------------------------
# Load env vars from file `../aws.env`
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/../.env

case ${1:-} in
    select)
        [ -z "${2:-}" ] && echo "Usage: $0 select [ azure | aws | google ]" && exit 1

        echo "Selecting cloud provider '$2'"
        cat $DIR/../.env | sed "s/CLOUD_PROVIDER=.*$/CLOUD_PROVIDER=$2/g" > $DIR/../.env
    ;;
    create)
        . $DIR/${CLOUD_PROVIDER}/create.sh
    ;;
    delete)
        . $DIR/${CLOUD_PROVIDER}/delete.sh
    ;;
    *)
        echo ""
        echo "Warning: Command requires an action:"
        echo " $0 [ select | create | delete ] "
        echo ""
        exit 1
    ;;
esac

