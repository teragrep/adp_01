#!/bin/bash
echo "Waiting for IPA to be up..";
while ! ping -c1 -w1 "ipa.${IPA_DOMAIN,,}" > /dev/null 2>&1; do
    sleep 1;
done;

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
DNS_REPLY="$(ipa dnsrecord-add "${IP_REV}.in-addr.arpa." "${IP_LAST}" --ptr-rec "$(hostname -f).")";
if grep "DNS zone not found" <<< "${DNS_REPLY}"; then
    echo "Failed to join to IPA: ${DNS_REPLY}";
    exit 1;
fi;
kdestroy -A;
