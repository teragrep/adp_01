#!/bin/bash
bash /entrypoint-common.sh nodemanager HTTP;

bash /scripts/copy_config.sh /config/hdp-03/ /opt/teragrep/hdp_03/etc/hadoop/ root:hadoop;
bash /scripts/copy_config.sh /config/spk-02/ /opt/teragrep/spk_02/conf/ root:root;

systemctl start nodemanager;
journalctl -fu nodemanager;
