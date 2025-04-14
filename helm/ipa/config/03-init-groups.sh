#!/bin/bash
create_group() {
    echo "Creating group ${1}";
    ipa group-add "${1}";
    USERS="";
    for group_user in "${@:2}"; do
        USERS+="--users=${group_user} ";
    done;
    ipa group-add-member "${1}" ${USERS};
}

{{- range $group, $users := .Values.ipa.groups }}
create_group {{$group}} {{$users}};
{{- end }}
