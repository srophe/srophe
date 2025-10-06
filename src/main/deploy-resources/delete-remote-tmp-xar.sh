#!/usr/bin/env sh

set -e

# Deletes a XAR file on a remote database server
## Expects the following environment variables:
# REMOTE_EDB_SERVER_USERNAME - username for authenticating to the remote database server
# REMOTE_EDB_SERVER_PASSWORD - password for authenticating to the remote database server
# REMOTE_EDB_SERVER_URL - URL of a remote database server to upload the XAR file into

curl --request DELETE --basic --user "${REMOTE_EDB_SERVER_USERNAME}:${REMOTE_EDB_SERVER_PASSWORD}" --fail-with-body "${REMOTE_EDB_SERVER_URL}/rest${db-tmp-collection}/${package-final-name}.xar"
