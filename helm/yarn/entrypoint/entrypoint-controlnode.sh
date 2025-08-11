#!/bin/bash
bash /entrypoint-common.sh jobhistoryserver resourcemanager HTTP;

bash /scripts/copy_config.sh /config/hdp-03/ /opt/teragrep/hdp_03/etc/hadoop/ root:hadoop;

systemctl start jobhistoryserver;
systemctl start resourcemanager;
journalctl -fu jobhistoryserver -fu resourcemanager;
