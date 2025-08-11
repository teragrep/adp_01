#!/bin/bash
create_host() {
    NEW_HOSTNAME="${1}.{{.Values.ipa.domain}}";
    echo "Creating new host ${NEW_HOSTNAME}";
    ipa host-add --force "${NEW_HOSTNAME}" --no-reverse;
    for service in "${@:2}"; do
        ipa service-add --force "${service}/${NEW_HOSTNAME}";
    done;
}

{{- range $host, $services := .Values.ipa.hosts }}
create_host {{$host}} {{$services}};
{{- end }}

# Special case for autocreating yarn and hdfs nodes
{{- range untilStep 1 (max 1 (.Values.hdfs.nodes) | add1 | int) 1 }}
create_host hdfs-datanode{{printf "%02d" .}} {{index $.Values.ipa.hostgroups "hdfs-datanode"}};
{{- end}}
{{- range untilStep 1 (max 1 (.Values.yarn.nodes) | add1 | int) 1 }}
create_host yarn-workernode{{printf "%02d" .}} {{index $.Values.ipa.hostgroups "yarn-workernode"}};
{{- end}}
