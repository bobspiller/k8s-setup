#!/bin/bash

PORT=${PORT:-2222}
IDENTITY_FILE=~/.vagrant.d/insecure_private_key
VUSER=${VUSER:-vagrant}

ssh -i ${IDENTITY_FILE} \
  -p ${PORT} \
  -o "NoHostAuthenticationForLocalhost yes" \
  ${VUSER}@localhost

