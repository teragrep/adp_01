#!/bin/bash
bash /scripts/patch_hosts.sh;

# Stores the ccaches in predictable place so the it will survive a container restart
sed -i 's,PrivateTmp=yes,PrivateTmp=off,g' /usr/lib/systemd/system/ipa-dnskeysyncd.service;
sed -i 's,PrivateTmp=on,PrivateTmp=off,g' /usr/lib/systemd/system/dirsrv@.service;
sed -i 's,PrivateTmp=true,PrivateTmp=off,g' /usr/lib/systemd/system/httpd.service;
sed -i 's,PrivateTmp=yes,PrivateTmp=off,g' /usr/lib/systemd/system/ipa-custodia.service;
sed -i 's,PrivateTmp=true,PrivateTmp=off,g' /usr/lib/systemd/system/named.service;
systemctl daemon-reload;
