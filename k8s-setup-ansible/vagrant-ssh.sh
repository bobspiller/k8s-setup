#!/bin/bash

PORT=${PORT:-2222}
IDENTITY_FILE=insecure_vagrant_docker_id
VUSER=${VUSER:-vagrant}

ssh -i ${IDENTITY_FILE} \
  -p ${PORT} \
  -o "NoHostAuthenticationForLocalhost yes" \
  ${VUSER}@localhost

