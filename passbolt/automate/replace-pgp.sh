#!/bin/bash

# download files from server dist

# extract them

# Start containers
docker compose up -d

# rentrer dans le container 
docker exec -it passbolt-passbolt-1 bash

# create mkdir
mkdir /tmp/gpg-temp

# create new pgp
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

# search gpg public key and export to tmp
gpg --homedir /tmp/gpg-temp --armor --export ${PASSBOLT_KEY_EMAIL:-admin.passbolt-server@proton.me} | tee /etc/passbolt/gpg/serverkey.asc > /dev/null

# search gpg private key and export to tmp
gpg --homedir /tmp/gpg-temp --armor --export-secret-key ${PASSBOLT_KEY_EMAIL:-admin.passbolt-server@proton.me} | tee /etc/passbolt/gpg/serverkey_private.asc > /dev/null

#change ownership
chown www-data:www-data /etc/passbolt/gpg/serverkey_private.asc
chown www-data:www-data /etc/passbolt/gpg/serverkey.asc

# check if the gpg keys are the same
gpg --show-keys /etc/passbolt/gpg/serverkey.asc | grep -Ev "^(pub|sub|uid|$)" | tr -d ' '
gpg --show-keys /etc/passbolt/gpg/serverkey_private.asc | grep -Ev "^(pub|sub|uid|$|sec|ssb)" | tr -d ' '

# do healthcheck and assign pgp key
su -s /bin/bash -c "/usr/share/php/passbolt/bin/cake passbolt healthcheck --gpg" www-data | grep GNUPGHOME

# remove dirs
rm -rf /var/lib/passbolt/.gnupg
rm -rf /tmp/gpg-temp