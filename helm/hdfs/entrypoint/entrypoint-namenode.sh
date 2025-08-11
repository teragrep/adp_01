#!/bin/bash
bash /entrypoint-common.sh namenode HTTP;
systemctl start namenode;
journalctl -fu namenode;
