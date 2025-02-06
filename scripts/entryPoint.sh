#!/bin/bash

SPAMD_FLAGS=""


if [ -z ${SPAMD_ALLOWED_IPS} ]; then
    echo "No SPAMD_ALLOWED_IPS set, exiting..."
    exit 1
fi

if [ -z ${SPAMD_MAX_CHILDREN} ]; then
    SPAMD_MAX_CHILDREN=5
fi

if [ -z ${SPAMD_PORT} ]; then
    SPAMD_PORT=9783
fi


if [ -n ${SPAMD_DEBUG} ]; then
    SPAMD_FLAGS="${SPAMD_FLAGS} -D"
fi


spamd -x --listen '*' -p ${SPAMD_PORT} --max-children ${SPAMD_MAX_CHILDREN} -A ${SPAMD_ALLOWED_IPS} ${SPAMD_FLAGS}