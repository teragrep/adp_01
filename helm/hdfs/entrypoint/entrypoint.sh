#!/bin/bash
{{- if .Values.development.tools.hdfs.enabled }}
dnf install -y {{.Values.development.tools.hdfs.items}}
{{ end }}

# Common scripts
bash /scripts/patch_resolv.sh;
bash /scripts/patch_hosts.sh;
bash /scripts/join_ipa.sh;

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

fix_keytab_perms() {
    chown -R root:hadoop /opt/teragrep/hdp_03/keytabs/;
    chmod 755 /opt/teragrep/hdp_03/keytabs;
    chmod 644 /opt/teragrep/hdp_03/keytabs/*.keytab;
}

if [[ "${HOSTNAME}" =~ "hdfs-namenode01" ]]; then
    echo "Namenode detected, managing namenode";

    for keytab in namenode HTTP; do
        get_keytab "${keytab}";
    done;
    fix_keytab_perms;

    # hdp_04
    echo "Getting hdp_04 keytab";
    ipa-getkeytab -s "ipa.${IPA_DOMAIN}" -p "srv-hdp_04/$(hostname).${IPA_DOMAIN,,}@${IPA_DOMAIN^^}" -k "/opt/teragrep/hdp_04/etc/srv-hdp_04.service.keytab";

    sudo su - hdfs -s "$(which bash)" -c "/opt/teragrep/hdp_03/bin/hdfs namenode -format teragrep"

    systemctl start namenode;

    ## FIXME ##
    echo "Sleeping a bit before leaving safemode and fixing permissions";
    sleep 10;

    # creds
    export KRB5CCNAME="/tmp/krb5cc_${UID}";
    kinit -kt /opt/teragrep/hdp_03/keytabs/namenode.service.keytab "namenode/$(hostname).${IPA_DOMAIN,,}@${IPA_DOMAIN^^}";

    # Leave safemode
    echo "Leaving safemode";
    /opt/teragrep/hdp_03/bin/hdfs dfsadmin -safemode leave;

    # Create bunch of permissions
    /opt/teragrep/hdp_03/bin/hdfs dfs -chown hdfs:hadoop /;
    /opt/teragrep/hdp_03/bin/hdfs dfs -chmod 775 /;
    /opt/teragrep/hdp_03/bin/hdfs dfs -mkdir -p /tmp/hadoop-yarn/nm-local-dir/usercache;
    /opt/teragrep/hdp_03/bin/hdfs dfs -chmod 1777 /tmp/hadoop-yarn/nm-local-dir/usercache;
    /opt/teragrep/hdp_03/bin/hdfs dfs -chown hadoop:hadoop /tmp/hadoop-yarn;
    /opt/teragrep/hdp_03/bin/hdfs dfs -chown hadoop:hadoop /tmp/hadoop-yarn/nm-local-dir;
    /opt/teragrep/hdp_03/bin/hdfs dfs -chown hadoop:hadoop /tmp/hadoop-yarn/nm-local-dir/usercache;

    cp -vf /config/hdp-04/configuration.properties /opt/teragrep/hdp_04/etc/;
    echo "Running hdp_04";
    systemctl start hdp_04;

    # Patch hdfs credentials to well known values. Reversed password from IPA are well known but different.
    {{- range $user, $password := .Values.ipa.users }}
    echo "Overriding '{{$user}}' password to '$(rev <<< {{$password}})' on hdfs.";
    echo -n "$(rev <<< {{$password}})" | /opt/teragrep/hdp_03/bin/hdfs dfs -put -f - "/user/{{$user}}/s3credential";
    /opt/teragrep/hdp_03/bin/hdfs dfs -chmod 400 "/user/{{$user}}/s3credential";
    /opt/teragrep/hdp_03/bin/hdfs dfs -chown "{{$user}}:{{$user}}" "/user/{{$user}}/s3credential";
    {{- end }}

    # Destroy current ticket
    kdestroy -A;
    unset KRB5CCNAME;

    echo "We are ready here";
    touch "/namenode.ready";
    journalctl -fu namenode;
else
    echo "Datanode detected, managing datanode";

    for keytab in datanode HTTP; do
        get_keytab "${keytab}";
    done;
    fix_keytab_perms;

    systemctl start datanode;
    journalctl -fu datanode;
fi;
