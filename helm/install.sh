#!/bin/bash
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 chartname";
    echo "This will uninstall and re-install the chart if it already exists.";
    exit 0;
fi;

if [ ! -f "${1}/Chart.yaml" ]; then
    echo "Invalid chart \"${1}\"";
    exit 1;
fi;
if helm status --namespace teragrep "${1}" > /dev/null 2>&1; then
    echo "Detected an older version, uninstalling it first..";
    ./uninstall.sh "${1}";
fi;

echo "Installing ${1}, it might take a while.";
helm install --timeout 15m --values values.yaml --wait --create-namespace --namespace teragrep "${1}" "${1}/";
