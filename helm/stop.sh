#!/bin/bash
for module in shareable ipa hdfs yarn archive archive-datasource teragrep; do
    echo "Uninstalling ${module}";
    (./uninstall.sh "${module}") &
done;

wait;
