#!/bin/bash
if [ -f /data/bootstrapped ]; then
    echo "Already bootstrapped, remove '/data/bootstrapped' and restart container to re-do the initialization";
    sleep inf;
fi;

# Common scripts
bash /scripts/patch_resolv.sh;
bash /scripts/patch_hosts.sh;
bash /scripts/join_ipa.sh;

# Prepare configs and such
bash /scripts/copy_config.sh /config/obj-01/ /opt/Fail-Safe/obj-01/etc/ srv-arcv:srv-arcv;
bash /scripts/copy_config.sh /config/rest-02-data-tool/ /opt/Fail-Safe/rest-02-data-tool/etc/ srv-arcv:srv-arcv;
mkdir -p /opt/Fail-Safe/obj-01/logs;
mkdir -p /srv/data/spool;
chown -R srv-arcv:srv-arcv /opt/Fail-Safe/obj-01/logs;

# Prepare data
echo "Running init scripts inside /config/init/";
for file in /config/init/*.sh; do
    echo "Executing init script ${file}";
    bash "${file}";
done;

# Make them immediately archivable
echo "Fixing timestamps and permissions";
find /srv/data/spool/ -type f -exec touch -d "24 hours ago" {} \;
chown -R srv-arcv:srv-arcv /srv;

# Create hosts files for data-tool
create_host() {
    HOST_MD5="MD5=$(md5sum <<< "${1}" | awk '{print $1}')";
    echo "Creating a host '${1}' with key '${HOST_MD5}'";
    mkdir "/opt/Fail-Safe/rest-02-data-tool/var/hosts/${HOST_MD5}";
    echo '{"instanceid":-1,"clustertype":"docker","clustermembertype":"standalone","licensetype":"ee"}' > "/opt/Fail-Safe/rest-02-data-tool/var/hosts/${HOST_MD5}/facter_node.json";
    jq -n --arg host "${1}" --arg key "${HOST_MD5}" '{"fqhost":$host,"hostname":$host,"if":["lo"],"ip":["127.0.0.1"],"key":$key}' > "/opt/Fail-Safe/rest-02-data-tool/var/hosts/${HOST_MD5}/${1}.conf.json";
}
echo "Creating data-tool hosts";
mkdir -p /opt/Fail-Safe/rest-02-data-tool/var/hosts;
{{- range $host, $ignored := .Values.archive.datagenerator.static.lookups.hosts }}
create_host "{{$host}}.{{$.Values.ipa.domain}}";
{{- end }}

# Create cfe-01 configuration for data-tool
update_cfe_01() {
    echo "Adding tag ${1} -> index ${2} mapping to generate_rsyslog_files.json";
    jq --arg tag "${1}" --arg index "${2}" '.files|=.+[{"index": $index, "sourcetype": ("teragrep:" + $tag + ":0"), "tag": $tag, "file": ("/logs/" + $tag + ".log"),  "retention_time": "P100Y", "application": $tag, "category": "audit"}]' /opt/Fail-Safe/rest-02-data-tool/var/cfe-01/generate_rsyslog_files.json > /opt/Fail-Safe/rest-02-data-tool/var/cfe-01/generate_rsyslog_files.json.tmp;
    mv /opt/Fail-Safe/rest-02-data-tool/var/cfe-01/generate_rsyslog_files.json.tmp /opt/Fail-Safe/rest-02-data-tool/var/cfe-01/generate_rsyslog_files.json;
}
echo "Creating data-tool cfe-01 configuration";
mkdir -p /opt/Fail-Safe/rest-02-data-tool/var/cfe-01;
echo '{"files": []}' > /opt/Fail-Safe/rest-02-data-tool/var/cfe-01/generate_rsyslog_files.json;
{{- range $tag, $index := .Values.archive.datagenerator.static.lookups.indexes }}
update_cfe_01 "{{$tag}}" "{{$index}}";
{{- end }}

# Import the configurations
echo "Running data-tool";
/usr/lib/jvm/jre-1.8.0-openjdk/bin/java -jar /opt/Fail-Safe/rest-02-data-tool/share/java/logcatalog-data-tool.jar --spring.config.location=/opt/Fail-Safe/rest-02-data-tool/etc/application.properties --link-hosts --loggroup=teragrep --update-existing  --hosts.root-path=/opt/Fail-Safe/rest-02-data-tool/var/hosts --files-info.root-path=/opt/Fail-Safe/rest-02-data-tool/var/cfe-01;

# Archive
echo "Running archive";
sudo su - srv-arcv -s /usr/bin/bash -c "/usr/lib/jvm/jre-1.8.0-openjdk/bin/java -Dlog4j.configurationFile=file:///opt/Fail-Safe/obj-01/etc/log4j2.xml -jar /opt/Fail-Safe/obj-01/share/java/logarchiver-batch.jar --once --spring.config.location=file:///opt/Fail-Safe/obj-01/etc/application.properties";

# Signal that we are ready to go
echo "We are ready here";
touch /data/bootstrapped;
