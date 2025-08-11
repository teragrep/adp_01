#!/bin/bash
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 chartname";
    echo "Installed charts:";
    for chart in $(helm list --short); do
        echo -e "\t${chart}";
    done;
    exit 0;
fi;

if ! helm status --namespace teragrep "${1}" > /dev/null 2>&1; then
    echo "Chart \"${1}\" does not exist";
    exit 0;
fi;

helm uninstall --wait --cascade foreground --namespace teragrep "${1}";
