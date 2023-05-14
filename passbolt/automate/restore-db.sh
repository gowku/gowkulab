#!/bin/bash


# Import backup-db.sql to passbolt-db-1 container
docker exec -i passbolt-db-1 bash -c 'mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}' < /home/gowku/backup-server-data/backup-db.sql

# Copy server keys to passbolt-passbolt-1 container
docker cp /home/gowku/backup-server-data/serverkey_private.asc passbolt-passbolt-1:/etc/passbolt/gpg/serverkey_private.asc
docker cp /home/gowku/backup-server-data/serverkey.asc passbolt-passbolt-1:/etc/passbolt/gpg/serverkey.asc

# Extract avatars archive to passbolt-passbolt-1 container
docker exec -i passbolt-passbolt-1 tar xvfzp - -C /usr/share/php/passbolt/ webroot/img/avatar < /home/gowku/backup-server-data/passbolt-avatars.tar.gz

# Stop running containers
docker compose down

# Start containers
docker compose up -d
