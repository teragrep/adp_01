#!/bin/bash
bash /entrypoint-common.sh

if [ -d /data/backup ]; then
    echo "Skipping init, already done.";
    systemctl exit 0;
fi;

echo "Bootstrapping server";
ipa-server-install --unattended --domain "{{.Values.ipa.domain | lower}}" --realm "{{.Values.ipa.domain | upper}}" --ds-password "{{.Values.ipa.password}}" --admin-password "{{.Values.ipa.password}}" --setup-dns --forwarder "{{.Values.ipa.forwarder}}" --forward-policy only --no-ntp --auto-reverse;

echo "Running start-up scripts inside /config";
echo "{{.Values.ipa.password}}" | kinit admin;
for file in /config/*.sh; do
    echo "Executing init script ${file}";
    bash "${file}";
done;

echo "Creating data dump";
ipa-backup;

echo "Moving the backup to well known location";
mv -v "$(find /var/lib/ipa/backup/ -type d -name "ipa-full*" | head -1)" /data/backup;

echo "Exiting";
systemctl exit 0;
