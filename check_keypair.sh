#!/bin/bash

KEYPAIR_NAME=$1

# Check if the keypair exists in OpenStack
openstack keypair show "${KEYPAIR_NAME}" > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo '{"exists": "true"}'
else
  echo '{"exists": "false"}'
fi