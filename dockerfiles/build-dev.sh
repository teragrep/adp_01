#!/bin/bash
set -e;
for container in teragrep ipa hdfs yarn archive archive-datagenerator-static mariadb; do
    echo "Building ${container}";
    docker build -t "teragrep/teragrep-cluster/${container}:dev" -f "Dockerfile.${container}" .;
done;
