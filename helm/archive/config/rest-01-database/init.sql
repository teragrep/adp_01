CREATE DATABASE {{.Values.archive.journal.database.name}} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
grant all privileges on {{.Values.archive.journal.database.name}}.* to {{.Values.archive.journal.database.username}}@'%' identified by '{{.Values.archive.journal.database.password}}';
flush privileges;
