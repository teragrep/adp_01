#!/bin/bash
# This makes true writable copies of the configuration files without copying any symlinks or such.
echo "Copying ${1} to ${2} owned by user ${3}";
find "${1}" -type f -exec cp -v {} "${2}" \;
chown -R "${3}" "${2}";
