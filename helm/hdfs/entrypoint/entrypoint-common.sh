#!/bin/bash
bash /scripts/patch_resolv.sh;
bash /scripts/patch_hosts.sh;
bash /scripts/join_ipa.sh || systemctl exit 1;

bash /scripts/copy_config.sh /config/hdp-03/ /opt/teragrep/hdp_03/etc/hadoop/ root:hadoop;

# Create datafolders
mkdir -p /opt/teragrep/dfs;
chown hdfs:hadoop /opt/teragrep/dfs;

# Get keytab
kinit -kt /etc/krb5.keytab;
mkdir -p /opt/teragrep/hdp_03/keytabs/;

# Generate jks
mkdir -p /opt/teragrep/hdp_03/jks/;
chmod 750 /opt/teragrep/hdp_03/jks/;
for store in client server; do
    keytool -genkey -storetype PKCS12 -dname "CN=$(hostname -f)" -alias "$(hostname -f)" -keyalg RSA -keystore "/opt/teragrep/hdp_03/jks/${store}-keystore.jks" -keysize 2048 -storepass "{{.Values.hdfs.jkspassword}}";
    keytool -noprompt -keystore "/opt/teragrep/hdp_03/jks/${store}-truststore.jks" -alias CARoot -import -trustcacerts -file "/etc/ssl/certs/ca-bundle.crt" -keypass "{{.Values.hdfs.jkspassword}}" -storepass "{{.Values.hdfs.jkspassword}}";
done;
chown -R hdfs:hadoop /opt/teragrep/hdp_03/jks/;
chmod 640 /opt/teragrep/hdp_03/jks/*.jks;

get_keytab() {
    echo "Getting keytab ${1}";
    ipa-getkeytab -s "ipa.${IPA_DOMAIN}" -p "${1}/$(hostname).${IPA_DOMAIN,,}@${IPA_DOMAIN^^}" -k "/opt/teragrep/hdp_03/keytabs/${1}.service.keytab";
}

for keytab in "${@}"; do
    get_keytab "${keytab}";
done;

chown -R root:hadoop /opt/teragrep/hdp_03/keytabs/;
chmod 755 /opt/teragrep/hdp_03/keytabs;
chmod 644 /opt/teragrep/hdp_03/keytabs/*.keytab;
