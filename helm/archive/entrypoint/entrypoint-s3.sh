#!/bin/bash
bash /entrypoint-common.sh "archive-journal-database.{{.Values.ipa.domain}}" "{{.Values.archive.journal.database.username}}" "{{.Values.archive.journal.database.password}}";

bash /scripts/copy_config.sh /config/bos-01/ /opt/teragrep/bos_01/etc/ srv-s3px:srv-s3px;
bash /scripts/copy_config.sh /config/pth-05/ /opt/teragrep/pth_05/etc/ srv-s3gw:srv-s3gw;

# Create storage directory and default bucket
mkdir -p /srv/teragrep/bos_01/hundred-year;
chown -R srv-s3px:srv-s3px /srv;

# Create pth_05 credentials to match well known values used in hdfs. Reversed password from IPA are well known but different.
create_credentials() {
    PASSWORD="$(rev <<< ${2})";
    echo "Adding user '${1}' with password '${PASSWORD}' to credentials.json.";
    jq --arg user "${1}" --arg password "${PASSWORD}" '.|=.+[{"identity": $user, "credential": $password}]' /opt/teragrep/pth_05/etc/credentials.json > /opt/teragrep/pth_05/etc/credentials.json.tmp;
    mv -f /opt/teragrep/pth_05/etc/credentials.json.tmp /opt/teragrep/pth_05/etc/credentials.json;
}

echo "[]" > /opt/teragrep/pth_05/etc/credentials.json;
{{- range $user, $password := .Values.ipa.users }}
create_credentials "{{$user}}" "{{$password}}";
{{- end }}

# Create pth_05 authorize to contain every group explicitly. All groups are allowed to access everything for the sake of easiness.
create_authorize() {
    echo "Adding group '${1}' to authorize.json.";
    jq --arg group "${1}" '.|=.+[{"group": $group, "allowedIndexes": ["*"]}]' /opt/teragrep/pth_05/etc/authorize.json > /opt/teragrep/pth_05/etc/authorize.json.tmp;
    mv -f /opt/teragrep/pth_05/etc/authorize.json.tmp /opt/teragrep/pth_05/etc/authorize.json;
}

echo "[]" > /opt/teragrep/pth_05/etc/authorize.json;
{{- range $group, $ignored := .Values.ipa.groups }}
create_authorize "{{$group}}";
{{- end }}

# Prepare lookup directory
mkdir -p /opt/teragrep/pth_05/etc/lookup/;
echo '{"version":1,"nomatch":"unknown","type":"string","table":[]}' > /opt/teragrep/pth_05/etc/lookup/teragrep_hosts.json;
echo '{"version":1,"nomatch":"unknown","type":"string","table":[]}' > /opt/teragrep/pth_05/etc/lookup/teragrep_indexes.json;

# Create lookup tables for each of the hosts
create_lookup_hosts() {
    echo "Adding '${1}' to teragrep_hosts.json.";
    jq --arg host "${1}" '.table|=.+[{"index": $host, "value": true}]' /opt/teragrep/pth_05/etc/lookup/teragrep_hosts.json > /opt/teragrep/pth_05/etc/lookup/teragrep_hosts.json.tmp;
    mv -f /opt/teragrep/pth_05/etc/lookup/teragrep_hosts.json.tmp /opt/teragrep/pth_05/etc/lookup/teragrep_hosts.json;
}
{{- range $host, $ignored := .Values.archive.datagenerator.static.lookups.hosts }}
create_lookup_hosts "{{$host}}.{{$.Values.ipa.domain}}";
{{- end }}

# Create lookup tables for each of the indexes
create_lookup_indexes() {
    echo "Adding '${1}' -> '${2}' mapping to teragrep_indexes.json.";
    jq --arg index "${1}" --arg value "${2}" '.table|=.+[{"index": $index, "value": $value}]' /opt/teragrep/pth_05/etc/lookup/teragrep_indexes.json > /opt/teragrep/pth_05/etc/lookup/teragrep_indexes.json.tmp;
    mv -f /opt/teragrep/pth_05/etc/lookup/teragrep_indexes.json.tmp /opt/teragrep/pth_05/etc/lookup/teragrep_indexes.json;
}
{{- range $index, $value := .Values.archive.datagenerator.static.lookups.indexes }}
create_lookup_indexes "{{$index}}" "{{$value}}";
{{- end }}

# Create sourcetypes tables for each. This is only used by streamdb import
mkdir -p /tmp/streamdb/lookup/;
echo '{"version":1,"nomatch":"unknown","type":"string","table":[]}' > /tmp/streamdb/lookup/teragrep_sourcetypes.json;
create_lookup_sourcetypes() {
    echo "Adding '${1}' mapping to teragrep_sourcetypes.json.";
    jq --arg tag "${1}" '.table|=.+[{"index": $tag, "value": ("log:"+$tag+":0")}]' /tmp/streamdb/lookup/teragrep_sourcetypes.json > /tmp/streamdb/lookup/teragrep_sourcetypes.json.tmp;
    mv -f /tmp/streamdb/lookup/teragrep_sourcetypes.json.tmp /tmp/streamdb/lookup/teragrep_sourcetypes.json;
}
{{- range $tag, $ignored := .Values.archive.datagenerator.static.lookups.indexes }}
create_lookup_sourcetypes "{{$tag}}";
{{- end }}
cp /opt/teragrep/pth_05/etc/lookup/teragrep_indexes.json /opt/teragrep/pth_05/etc/lookup/teragrep_hosts.json /tmp/streamdb/lookup/;

# This maybe should be done in a nicer way but re-using pth_05 configurations for streamd importing.
echo "Importing streamdb configurations from pth_05";
python3 /opt/Fail-Safe/tools/rest-03/config_to_db.py /tmp/streamdb/lookup/ > /tmp/streamdb/import.sql;
mysql -h archive-journal-database.{{.Values.ipa.domain}} -u {{.Values.archive.streamdb.database.username}} -p{{.Values.archive.streamdb.database.password}} -D {{.Values.archive.streamdb.database.name}} < /tmp/streamdb/import.sql;
echo "Streamdb imported";

# HACK: Adding logback configuration directly to the servicefile: https://github.com/teragrep/bos_01/issues/9
echo "Patching bos_01 service for logback configuration";
sed -i 's,-cp,-Dlogback.configurationFile=/opt/teragrep/bos_01/etc/logback.xml -cp,g' /usr/lib/systemd/system/bos_01.service;
# FIXME: This is a hack, https://github.com/teragrep/bos_01/issues/10 & https://github.com/teragrep/bos_01/issues/11 - bos_01 actually requires java 11
echo "Patching bos_01 service for direct java path";
update-alternatives --set java java-11-openjdk.x86_64;
sed -i 's,/usr/bin/java,/usr/lib/jvm/jre-11-openjdk/bin/java,g' /usr/lib/systemd/system/bos_01.service
# Start processes
echo "Starting processes";
systemctl start bos_01;
systemctl start pth_05;
journalctl -fu bos_01 -fu pth_05;
