#!/bin/bash
bash /entrypoint-common.sh;

if [ ! -d /data/backup ]; then
    echo "No /data/backup, init was not properly executed?";
    exit 1;
fi;

# Asks for password and confirmation.
echo "Init already done, restoring from backup..";
echo -e "{{.Values.ipa.password}}\ny" | ipa-restore /data/backup;
echo "Backup restored, following the logs.";

# Required to survive Minikube restart. No modifications results in error so running '|| true' is easier than checking whether current ip is what is configured.
echo "Attempting to set a new DNS entry for IPA";
echo "{{.Values.ipa.password}}" | kinit admin;
ipa dnsrecord-mod tg.dev.test ipa --a-rec="$(hostname -I)" 2>/dev/null || true;

# Additional check for liveness
touch /ipa.ready;

# This should never return
journalctl -fu ipa;

# Failure state detected
systemctl exit 1;
