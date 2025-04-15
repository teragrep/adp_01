#!/bin/bash
set -e;
echo "Stopping all existing modules";
./stop.sh;
for module in shareable ipa hdfs yarn archive archive-datagenerator-static teragrep; do
    if ! ./install.sh "${module}" "$@"; then
        echo "Failure detected, stopping everything.";
        ./stop.sh;
        exit 1;
    fi;
done;

minikube service teragrep-nodeport --namespace teragrep;
