#!/bin/bash
bash /entrypoint-common.sh;

echo "Fetching server certificate";
ipa-getcert request --certfile /etc/pki/tls/certs/mariadb.crt --keyfile /etc/pki/tls/certs/mariadb.key --subject-name "CN=$(hostname -f)" --dns "$(hostname -f)" --principal "host/$(hostname -f)" --wait;
chown mysql:mysql /etc/pki/tls/certs/mariadb.key /etc/pki/tls/certs/mariadb.crt;

# First initialize the database
if [ ! -f /data/bootstrapped ]; then
    mariadb-install-db --user=mysql --ldata=/var/lib/mysql/
fi;

echo "Starting database";
systemctl start mariadb;
echo "Waiting for database to get up";
while ! mariadb <<< "select 1;" > /dev/null 2>&1; do
    sleep 1;
done;

# Then import all the necessary configurations
if [ ! -f /data/bootstrapped ]; then
    echo "Not bootstrapped, importing data";
    for importfile in /config/*.sql; do

        mariadb < "${importfile}";
    done;
    touch /data/bootstrapped;
fi;

echo "Starting journalctl for database";
journalctl --boot -fu mariadb;
