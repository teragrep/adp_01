#!/bin/bash
echo "Joining to IPA";
if ! ipa-client-install --force-join --ip-address "$(hostname -i)" --server "ipa.${IPA_DOMAIN,,}" --domain "${IPA_DOMAIN,,}" --realm "${IPA_DOMAIN^^}" --unattended --no-ntp --principal "admin@${IPA_DOMAIN^^}" --password "${IPA_PASSWORD}"; then
    echo "Failed to enroll to IPA, refusing to continue.";
    exit 1;
fi;

echo "Creating new PTR for this machine";
IP="$(hostname -i)";
IP_REV="$(sed "s,^\([0-9]\+\)\.\([0-9]\+\)\.\([0-9]\+\)\.[0-9]\+,\3\.\2\.\1,g" <<< $IP)";
IP_LAST="$(sed "s,.*\.\([0-9]\+\)$,\1,g" <<< $IP)";

kinit admin <<< "${IPA_PASSWORD}";
ipa dnsrecord-add "${IP_REV}.in-addr.arpa." "${IP_LAST}" --ptr-rec "$(hostname -f).";
kdestroy -A;
