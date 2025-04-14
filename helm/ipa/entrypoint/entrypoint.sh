#!/bin/bash
{{- if .Values.development.tools.ipa.enabled }}
dnf install -y {{.Values.development.tools.ipa.items}}
{{ end }}

bash /scripts/patch_hosts.sh;

echo "Bootstrapping server";
ipa-server-install --unattended --domain "{{.Values.ipa.domain | lower}}" --realm "{{.Values.ipa.domain | upper}}" --ds-password "{{.Values.ipa.password}}" --admin-password "{{.Values.ipa.password}}" --setup-dns --forwarder "{{.Values.ipa.forwarder}}" --forward-policy only --no-ntp --auto-reverse;

echo "Running start-up scripts inside /config";
for file in /config/*.sh; do
    echo "Executing init script ${file}";
    bash "${file}";
done;

touch /ipa.ready;

echo "######   #######     #     ######   #     #";
echo "#     #  #          # #    #     #   #   #";
echo "#     #  #         #   #   #     #    # #";
echo "######   #####    #     #  #     #     #";
echo "#   #    #        #######  #     #     #";
echo "#    #   #        #     #  #     #     #";
echo "#     #  #######  #     #  ######      #";
