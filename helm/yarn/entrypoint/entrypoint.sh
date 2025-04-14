#!/bin/bash
{{- if .Values.development.tools.yarn.enabled }}
dnf install -y {{.Values.development.tools.yarn.items}}
{{ end }}

# Common scripts
bash /scripts/patch_resolv.sh;
bash /scripts/patch_hosts.sh;
bash /scripts/join_ipa.sh;

bash /scripts/copy_config.sh /config/hdp-03/ /opt/teragrep/hdp_03/etc/hadoop/ root:hadoop;
bash /scripts/copy_config.sh /config/spk-02/ /opt/teragrep/spk_02/conf/ root:root;

# Get keytab
kinit -kt /etc/krb5.keytab;
mkdir -p /opt/teragrep/hdp_03/keytabs/;

get_keytab() {
    echo "Getting keytab ${1}";
    ipa-getkeytab -s "ipa.${IPA_DOMAIN}" -p "${1}/$(hostname).${IPA_DOMAIN,,}@${IPA_DOMAIN^^}" -k "/opt/teragrep/hdp_03/keytabs/${1}.service.keytab";
}

fix_perms() {
    chown -R root:hadoop /opt/teragrep/hdp_03/keytabs/;
    chmod 755 /opt/teragrep/hdp_03/keytabs;
    chmod 644 /opt/teragrep/hdp_03/keytabs/*.keytab;
}

if [[ "${HOSTNAME}" =~ "yarn-controlnode01" ]]; then
    echo "Controlnode detected, managing jobhistoryserver and resourcemanager";

    for keytab in jobhistoryserver resourcemanager HTTP; do
        get_keytab "${keytab}";
    done;
    fix_perms;

    systemctl start jobhistoryserver;
    systemctl start resourcemanager;
    journalctl -fu jobhistoryserver -fu resourcemanager;
else
    echo "Workernode detected, managing nodemanager";

    for keytab in nodemanager HTTP; do
        get_keytab "${keytab}";
    done;
    fix_perms;

    systemctl start nodemanager;
    journalctl -fu nodemanager;
fi;
