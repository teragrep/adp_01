#!/bin/bash
echo "Make sure no pods are running while syncing images";
( minikube image load teragrep/teragrep-cluster/teragrep:dev --overwrite=true --daemon=true; ) &
( minikube image load teragrep/teragrep-cluster/ipa:dev --overwrite=true --daemon=true; ) &
( minikube image load teragrep/teragrep-cluster/hdfs:dev --overwrite=true --daemon=true; ) &
( minikube image load teragrep/teragrep-cluster/yarn:dev --overwrite=true --daemon=true; ) &
( minikube image load teragrep/teragrep-cluster/archive:dev --overwrite=true --daemon=true; ) &
( minikube image load teragrep/teragrep-cluster/archive-datagenerator-static:dev --overwrite=true --daemon=true; ) &
( minikube image load teragrep/teragrep-cluster/mariadb:dev --overwrite=true --daemon=true; ) &
wait;
