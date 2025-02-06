#!/bin/bash

if [ -z ${SPAMD_ALLOWED_IPS} ]; then
    echo "No SPAMD_ALLOWED_IPS set, exiting..."
    exit 1
fi

if [ -z ${SPAMD_MAX_CHILDREN} ]; then
    SPAMD_MAX_CHILDREN=5
fi

spamd -x --listen '*' --max-children ${SPAMD_MAX_CHILDREN} -D -A ${SPAMD_ALLOWED_IPS}