#!/bin/bash
bash /entrypoint-common.sh "archive-catalog-database.{{.Values.ipa.domain}}" "{{.Values.archive.catalog.database.username}}" "{{.Values.archive.catalog.database.password}}";

bash /scripts/copy_config.sh /config/ /opt/Fail-Safe/rest-02-backend/etc/ srv-arcv:srv-arcv;
echo "Starting catalog";
update-alternatives --set java java-1.8.0-openjdk.x86_64;
systemctl start rest-02-backend;
journalctl -fu rest-02-backend;
