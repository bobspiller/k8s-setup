#!/bin/bash

NOLOGIN_FILE=/run/nologin

while /bin/true; do
    if [ -f "${NOLOGIN_FILE}" ]; then
        echo "Removing: $(ls -l ${NOLOGIN_FILE}) ..."
        rm -f ${NOLOGIN_FILE}
        echo "... done"
        exit 0
    fi

    sleep 5
done