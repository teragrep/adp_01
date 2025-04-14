#!/bin/bash
create_user() {
    echo "Creating user ${1}";
    ipa user-add --first="${1}" --last=Service --homedir="/home/${1}" --shell="$(which bash)" --email="${1}@{{.Values.ipa.domain}}" --password "${1}" <<< "${2}";
    ipa user-mod "${1}" --password-expiration="$(date --date="10 years" "+%Y-%m-%d %H:%M:%SZ")";
    ipa user-unlock "${1}";
}

{{- range $user, $password := .Values.ipa.serviceusers }}
create_user {{$user}} "{{$password}}";
{{- end }}

{{- range $user, $password := .Values.ipa.users }}
create_user {{$user}} "{{$password}}";
{{- end }}
