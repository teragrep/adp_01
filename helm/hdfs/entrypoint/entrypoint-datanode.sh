#!/bin/bash
bash /entrypoint-common.sh datanode HTTP;
systemctl start datanode;
journalctl -fu datanode;
