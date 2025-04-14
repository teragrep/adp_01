#!/bin/bash
echo "{{.Values.ipa.password}}" | kinit admin;
