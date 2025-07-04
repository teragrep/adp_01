#!/bin/bash
bash /entrypoint-common.sh "archive-journal-database.{{.Values.ipa.domain}}" "{{.Values.archive.journal.database.username}}" "{{.Values.archive.journal.database.password}}";

bash /scripts/copy_config.sh /config/ /opt/Fail-Safe/rest-01/etc/ srv-arcv:srv-arcv;
echo "Starting journal";
update-alternatives --set java java-1.8.0-openjdk.x86_64;
systemctl start rest-01;
journalctl -fu rest-01;
