#!/bin/bash
echo "Make sure no pods are running while syncing images";
if [ ! -d images ]; then
    mkdir images;
fi;

sync() {
    echo "Syncing image ${1}";
    podman save -o "images/${1}.tar" "localhost/teragrep/teragrep-cluster/${1}:dev";
    minikube image rm "localhost/teragrep/teragrep-cluster/${1}:dev";
    minikube image load "images/${1}.tar" --overwrite=true --daemon=false;
    rm -fv "images/${1}.tar";
}
for image in teragrep ipa hdfs yarn archive archive-datagenerator-static mariadb; do
    sync "${image}";
done;
