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
create_host {{$host}} {{$services }};
{{- end }}
