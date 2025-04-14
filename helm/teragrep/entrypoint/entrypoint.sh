#!/bin/bash
{{- if .Values.development.tools.teragrep.enabled }}
dnf install -y {{.Values.development.tools.teragrep.items}}
{{ end }}

# Common scripts
bash /scripts/patch_resolv.sh;
bash /scripts/patch_hosts.sh;
bash /scripts/join_ipa.sh;

# Get keytab
kinit -kt /etc/krb5.keytab;
mkdir -p /opt/teragrep/keytabs/;
ipa-getkeytab -s "ipa.${IPA_DOMAIN}" -p "zeppelin/teragrep.${IPA_DOMAIN,,}@${IPA_DOMAIN^^}" -k /opt/teragrep/keytabs/zeppelin.keytab
chown -R srv-zpln:srv-zpln /opt/teragrep/keytabs;

# This makes true writable copies of the configuration files without copying any symlinks or such.
bash /scripts/copy_config.sh /config/teragrep/ /opt/teragrep/zep_01/conf/ srv-zpln:srv-zpln;
bash /scripts/copy_config.sh /config/hdp-03/ /opt/teragrep/hdp_03/etc/hadoop/ root:hadoop;
bash /scripts/copy_config.sh /config/spk-02/ /opt/teragrep/spk_02/conf/ root:root;

# Limited subset of items, not using copy_config.sh
mkdir -p /opt/teragrep/zep_01/notebook;
find /notebooks/ -type f -name "*.zpln" -exec cp {} /opt/teragrep/zep_01/notebook/ \;
chown -R srv-zpln:srv-zpln /opt/teragrep/zep_01/notebook/;

echo "Starting zep_01";
systemctl start zep_01;

journalctl -fu zep_01;
