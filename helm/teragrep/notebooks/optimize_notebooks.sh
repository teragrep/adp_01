#!/bin/bash
if ! command -v jq >/dev/null 2>&1; then
    echo "This script requires 'jq' to be installed.";
    exit 1;
fi

for notebook in *.zpln; do
    jq '
       del(.paragraphs[].results) |
       del(.angularObjects) |
       .paragraphs[].user="dummy-user" |
       .paragraphs[].dateUpdated="2001-01-01 01:01:01.000" |
       .paragraphs[].dateCreated="2001-01-01 01:01:01.000" |
       .paragraphs[].dateStarted="2001-01-01 01:01:01.000" |
       .paragraphs[].dateFinished="2001-01-01 01:01:01.000" |
       .paragraphs[].status="READY"
       ' "${notebook}" > "${notebook}.tmp";
    mv -fv "${notebook}.tmp" "${notebook}";
done;
