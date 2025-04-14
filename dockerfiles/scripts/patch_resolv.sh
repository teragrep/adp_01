#!/bin/bash
echo "Patching resolv configuration";
echo -e "nameserver ${IPA_SERVICE_HOST}\nsearch ${IPA_DOMAIN,,}\noptions ndots:5" > /etc/resolv.conf;
echo "Resolv configuration patched";
