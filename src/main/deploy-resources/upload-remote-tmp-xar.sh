#!/usr/bin/env sh

set -e


# Uploads a XAR file to a remote database server
## Expects the following environment variables:
# REMOTE_EDB_SERVER_USERNAME - username for authenticating to the remote database server
# REMOTE_EDB_SERVER_PASSWORD - password for authenticating to the remote database server
# REMOTE_EDB_SERVER_URL - URL of a remote database server to upload the XAR file into

if [ $# -eq 0 ]; then
    XAR_PATH="${package-final-name}.xar"
else
    XAR_PATH=$1
fi

curl --request PUT --basic --user "${REMOTE_EDB_SERVER_USERNAME}:${REMOTE_EDB_SERVER_PASSWORD}" --header 'Content-Type: application/expath+xar' --data-binary "@${XAR_PATH}" --fail-with-body "${REMOTE_EDB_SERVER_URL}/rest${db-tmp-collection}/${package-final-name}.xar"
