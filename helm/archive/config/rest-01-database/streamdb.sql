CREATE DATABASE {{.Values.archive.streamdb.database.name}} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE {{.Values.archive.streamdb.database.name}};

CREATE TABLE `log_group` (
`id` INT unsigned NOT NULL auto_increment,
`name` VARCHAR(100) NOT NULL,
PRIMARY KEY(`id`)
);

CREATE TABLE `host` (
`id` INT unsigned NOT NULL auto_increment,
`name` VARCHAR(175) NOT NULL,
`gid` INT unsigned NOT NULL,
-- FOREIGN KEY (`name`) references journaldb.host(`name`),
FOREIGN KEY (`gid`) references `log_group`(`id`) on delete cascade,
PRIMARY KEY(`id`)
);

CREATE INDEX idx_name_id ON host (name,id); -- for host based searches

CREATE TABLE `stream` (
`id` INT unsigned NOT NULL auto_increment,
`gid` INT unsigned NOT NULL,
`directory` VARCHAR(255) NOT NULL,
`stream` VARCHAR(255) NOT NULL,
`tag` VARCHAR(48) NOT NULL,
FOREIGN KEY (`gid`) references `log_group`(`id`) on delete cascade,
PRIMARY KEY(`id`)
);

-- User creation, allow streamdb to access streamdb
GRANT ALL PRIVILEGES on {{.Values.archive.streamdb.database.name}}.* to {{.Values.archive.streamdb.database.username}}@'%' identified by '{{.Values.archive.streamdb.database.password}}';
-- Allow streamdb to access journaldb
grant SELECT on {{.Values.archive.journal.database.name}}.* to {{.Values.archive.streamdb.database.username}}@'%' identified by '{{.Values.archive.streamdb.database.password}}';
flush privileges;
