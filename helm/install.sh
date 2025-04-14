#!/bin/bash
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 chartname [alternative_values_file]";
    echo "This will uninstall and re-install the chart if it already exists. Adding any secondary argument will use values-XXX.yaml instead.";
    exit 0;
fi;

if [ ! -f "${1}/Chart.yaml" ]; then
    echo "Invalid chart \"${1}\"";
    exit 1;
fi;

if [ -z "$2" ]; then
    echo "Using default values files.";
    VALUES_FILE="${1}/values.yaml";
    CONFIG_FILE="config.yaml"
else
    echo "Using custom \"${2}\" values files.";
    VALUES_FILE="${1}/values-${2}.yaml";
    CONFIG_FILE="config-${2}.yaml"
fi;

if [ ! -f "${VALUES_FILE}" ]; then
    echo "Missing \"${VALUES_FILE}\" file";
    exit 1;
fi;

if [ ! -f "${CONFIG_FILE}" ]; then
    echo "Missing \"${CONFIG_FILE}\" file";
    exit 1;
fi;

if helm status --namespace teragrep "${1}" > /dev/null 2>&1; then
    echo "Detected an older version, uninstalling it first..";
    ./uninstall.sh "${1}";
fi;

echo "Installing ${1}, it might take a while.";
if ! helm install --timeout 15m --wait --values "${CONFIG_FILE}" --values "${VALUES_FILE}" --create-namespace --namespace teragrep "${1}" "${1}/"; then
    if helm status --namespace teragrep "${1}" > /dev/null 2>&1; then
        echo "Detected a failure during installation, tearing down..";
        ./uninstall.sh "${1}";
        exit 1;
    fi;
fi;
