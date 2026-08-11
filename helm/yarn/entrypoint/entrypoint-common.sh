#!/bin/bash
# Common scripts
bash /scripts/patch_resolv.sh;
bash /scripts/patch_hosts.sh;
bash /scripts/join_ipa.sh || systemctl exit 1;

# Get keytab
kinit -kt /etc/krb5.keytab;
mkdir -p /opt/teragrep/hdp_03/keytabs/;

# Create JKS directories
mkdir -p /opt/teragrep/hdp_03/jks/;
chmod 755 /opt/teragrep/hdp_03/jks/;

# Import CA cert
keytool -import -noprompt -alias ca -file /etc/ssl/certs/ca-bundle.crt -keystore "/opt/teragrep/hdp_03/jks/truststore.jks" -storepass "{{.Values.jks.password}}";

# Create keypair
keytool -genkeypair -storetype PKCS12 -alias "$(hostname -f)" -keyalg RSA -keysize 2048 -dname "CN=$(hostname -f)" -keystore "/opt/teragrep/hdp_03/jks/keystore.jks" -storepass "{{.Values.jks.password}}" -keypass "{{.Values.jks.password}}";

# Extract CSR
keytool -certreq -alias "$(hostname -f)" -keystore "/opt/teragrep/hdp_03/jks/keystore.jks" -storepass "{{.Values.jks.password}}" -file "/opt/teragrep/hdp_03/jks/keystore.csr";

# Submit CSR to be signed
ipa cert-request "/opt/teragrep/hdp_03/jks/keystore.csr" --principal="HTTP/$(hostname -f)" --certificate-out="/opt/teragrep/hdp_03/jks/keystore.crt";

# Import CA cert to the keystore
keytool -import -noprompt -alias ca -file /etc/ssl/certs/ca-bundle.crt -keystore "/opt/teragrep/hdp_03/jks/keystore.jks" -storepass "{{.Values.jks.password}}";

# Import signed certificate to the keystore
keytool -import -noprompt -alias "$(hostname -f)" -file "/opt/teragrep/hdp_03/jks/keystore.crt" -keystore "/opt/teragrep/hdp_03/jks/keystore.jks" -storepass "{{.Values.jks.password}}";

# Set permissions
chown -R yarn:hadoop /opt/teragrep/hdp_03/jks/;
chmod 644 /opt/teragrep/hdp_03/jks/*.jks;

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
