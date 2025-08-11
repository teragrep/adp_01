CREATE DATABASE {{.Values.archive.catalog.database.name}} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
grant all privileges on {{.Values.archive.catalog.database.name}}.* to {{.Values.archive.catalog.database.username}}@'%' identified by '{{.Values.archive.catalog.database.password}}';
flush privileges;
