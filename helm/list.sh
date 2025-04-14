#!/bin/bash
echo "Available charts:";
for repo in */Chart.yaml; do
    echo -en "\t$(dirname "${repo}")";
    if ! helm --namespace teragrep status "$(dirname "${repo}")" > /dev/null 2>&1; then
        echo " - Not installed";
    else
        echo " - Installed";
    fi;
done;

echo "--";
echo "Helm list:";
helm list --namespace teragrep;
for resource in pods secrets configmaps services; do
    echo "--";
    echo "kubectl ${resource}:";
    kubectl get "${resource}" --output wide --namespace teragrep;
done;
