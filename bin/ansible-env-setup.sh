#!/bin/bash

virtualenv_installed() {
    ${PIP_CMD} show virtualenv > /dev/null 2> /dev/null
}

if [ ${#} -lt 1 ]; then
    echo "Usage: $0 <ansible-version>"
    exit 1
fi

set -x
ANSIBLE_VERSION=$1

PYTHON_CMD=${PYTHON_CMD:-python3}
PIP_CMD=${PIP_CMD:-pip3}

if  ! virtualenv_installed;  then
    ${PIP_CMD} install --user virtualenv
fi

VENV_DIR=${VENV_DIR:-${HOME}/virtualenv}

if [ ! -d "${VENV_DIR}" ]; then
    mkdir -p ${VENV_DIR}
fi

cd ${VENV_DIR}
VENV_NAME=ansible-${ANSIBLE_VERSION}
${PYTHON_CMD} -m virtualenv ${VENV_NAME}
cd ${VENV_NAME}
source bin/activate
${PIP_CMD} install ansible==${ANSIBLE_VERSION}

# Install stuff needed for Ansible playbooks
${PIP_CMD} install jmespath
