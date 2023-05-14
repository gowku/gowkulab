#!/bin/bash

# save the data : 

# create tmp dir and backup
mkdir tmp/backup/

# dump sql database
docker exec -i passbolt-db-1 bash -c   'mysqldump -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}'   > ./tmp/backup/backup-db.sql

# copy server private key
docker cp passbolt-passbolt-1:/etc/passbolt/gpg/serverkey_private.asc ./tmp/backup/gpg/serverkey_private.asc

# copy server public key
docker cp passbolt-passbolt-1:/etc/passbolt/gpg/serverkey.asc ./tmp/backup/gpg/serverkey.asc

# create an archive of avatars and copy to tmp/backup/
docker exec -i passbolt-passbolt-1 tar cvfzp - -C /usr/share/php/passbolt/ webroot/img/avatar     > ./tmp/backup/passbolt-avatars.tar.gz

#extract the archive 
tar -cvzf ./tmp/backup.tar.gz ./tmp/backup/

# send the data to the new server:
scp /home/gowku/backup-server-data.tar.gz gowku@192.168.1.128:/home


