#!/bin/bash
# Common scripts
bash /scripts/patch_resolv.sh;
bash /scripts/patch_hosts.sh;
bash /scripts/join_ipa.sh || systemctl exit 1;

# Wait for database to be up if right amount of arguments are passed.
if [ "$#" -eq 3 ]; then
    echo "Attempting to connect to database ${1} as user ${2}";
    while ! mariadb -h "${1}" -u "${2}" -p"${3}" <<< "select 1;" > /dev/null 2>&1; do
        sleep 1;
    done;
    echo "Database up, continuing";
fi;
