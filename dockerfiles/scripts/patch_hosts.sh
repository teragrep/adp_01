#!/bin/bash
echo "Patching hosts file";
# The file is managed by kubernetes and can't be deleted so some redirection trickery is necessary
sed "s,\($(hostname -I | awk '{print $1}')\),\1 $(hostname).${IPA_DOMAIN,,},g" /etc/hosts > /etc/hosts.tmp;
cat /etc/hosts.tmp > /etc/hosts;
rm /etc/hosts.tmp;
echo "Hosts file patched";
