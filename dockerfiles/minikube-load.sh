#!/bin/bash
echo "Make sure no pods are running while syncing images";
if [ ! -d images ]; then
    mkdir images;
fi;

sync() {
    echo "Syncing image ${1}";
    podman save -o "images/${1//\//_}.tar" "localhost/teragrep/adp_01/${1}:dev";
    minikube image load "images/${1//\//_}.tar" --overwrite=true --daemon=false;
    rm -fv "images/${1//\//_}.tar";
}

for container in teragrep ipa yarn/workernode yarn/controlnode hdfs archive/s3 archive-datagenerator-static archive/catalog mariadb archive/journal; do
    sync "${container}";
done;
