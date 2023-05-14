#!/bin/bash

docker compose --env-file /home/gowku/passbolt/.env -f /home/gowku/passbolt/docker-compose-ce.yaml up -d

docker compose -f /home/gowku/passbolt/docker-compose-ce.yaml exec passbolt su -m -c "/usr/share/php/passbolt/bin/cake \
                                passbolt register_user \
                                -u admin.passbolt-server@proton.me \
                                -f admin \
                                -l passbolt-server \
                                -r admin" -s /bin/sh www-data

docker exec -it passbolt-passbolt-1 bash

mkdir /tmp/gpg-temp

gpg --homedir /tmp/gpg-temp --batch --no-tty --gen-key <<EOF
    Key-Type: default
    Key-Length: ${PASSBOLT_KEY_LENGTH:-2048}
    Subkey-Type: default
    Subkey-Length: ${PASSBOLT_SUBKEY_LENGTH:-2048}
    Name-Real: ${PASSBOLT_KEY_NAME:-admin}
    Name-Email: ${PASSBOLT_KEY_EMAIL:-admin.passbolt-server@proton.me}
    Expire-Date: ${PASSBOLT_KEY_EXPIRATION:-0}
    %no-protection
    %commit
EOF

gpg --homedir /tmp/gpg-temp --armor --export ${PASSBOLT_KEY_EMAIL:-admin.passbolt-server@proton.me} | tee /etc/passbolt/gpg/serverkey.asc > /dev/null

gpg --homedir /tmp/gpg-temp --armor --export-secret-key ${PASSBOLT_KEY_EMAIL:-admin.passbolt-server@proton.me} | tee /etc/passbolt/gpg/serverkey_private.asc > /dev/null

chown www-data:www-data /etc/passbolt/gpg/serverkey_private.asc
chown www-data:www-data /etc/passbolt/gpg/serverkey.asc

gpg --show-keys /etc/passbolt/gpg/serverkey.asc | grep -Ev "^(pub|sub|uid|$)" | tr -d ' '
gpg --show-keys /etc/passbolt/gpg/serverkey_private.asc | grep -Ev "^(pub|sub|uid|$|sec|ssb)" | tr -d ' '

su -s /bin/bash -c "/usr/share/php/passbolt/bin/cake passbolt healthcheck --gpg" www-data | grep GNUPGHOME

rm -rf /var/lib/passbolt/.gnupg

rm -rf /tmp/gpg-temp

docker compose -f /home/gowku/passbolt/docker-compose-ce.yaml down

docker compose --env-file /home/gowku/passbolt/.env -f /home/gowku/passbolt/docker-compose-ce.yaml up -d
