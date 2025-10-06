#!/usr/bin/env bash

set -e

# Send a query to have a remote database server redeploy a XAR package
## Expects the following environment variables:
# REMOTE_EDB_SERVER_USERNAME - username for authenticating to the remote database server
# REMOTE_EDB_SERVER_PASSWORD - password for authenticating to the remote database server
# REMOTE_EDB_SERVER_URL - URL of a remote database server to upload the XAR file into

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Read in the XQuery file
XQUERY=`cat ${SCRIPT_DIR}/redeploy-xar-package.xq`

POST_BODY=`cat << EOF
<query xmlns="http://exist.sourceforge.net/NS/exist" cache="no" enclose="no" start="1" max="-1">
  <text><![CDATA[
  ${XQUERY}
  ]]></text>
</query>
EOF
`

echo "${POST_BODY}" | curl --request POST --basic --user "${REMOTE_EDB_SERVER_USERNAME}:${REMOTE_EDB_SERVER_PASSWORD}" --header "Content-Type: application/xml" --data-binary @- --fail-with-body "${REMOTE_EDB_SERVER_URL}/rest${db-tmp-collection}"
