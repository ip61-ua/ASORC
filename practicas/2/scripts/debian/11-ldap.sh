#!/bin/bash

# Instala herramientas de ldap (contraseña: 1)
apt -y install slapd ldap-utils phpldapadmin
# dc=debian,dc=asorc,dc=org

# Moverse al directorio del usuario root
cd ~/

# Jerarquizar grupos del directorio
cat << 'EOF' > base.ldif
dn: ou=people,dc=debian,dc=asorc,dc=org
objectClass: organizationalUnit
ou: people

dn: ou=groups,dc=debian,dc=asorc,dc=org
objectClass: organizationalUnit
ou: groups
EOF

# Establacer contraseña de admin de LDAP
echo '1
' | ldapadd -x -D cn=admin,dc=debian,dc=asorc,dc=org -W -f base.ldif

# Generar contraseña encriptada
echo << 'EOF' | slappasswd
1
1
EOF

# Declarar usuario de ejemplo, trixie.
# Es un usuario normal con su shell y como contraseña 1, aunque esta esté encriptada.
echo -e 'dn: uid=trixie,ou=people,dc=debian,dc=asorc,dc=org
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: trixie
sn: debian
userPassword: {SSHA}u32m9W6OrdI/A2EYZz7hPEFjma5wy82S
loginShell: /bin/bash
uidNumber: 2000
gidNumber: 2000
homeDirectory: /home/trixie

dn: cn=trixie,ou=groups,dc=debian,dc=asorc,dc=org
objectClass: posixGroup
cn: trixie
gidNumber: 2000
memberUid: trixie' > ldapuser.ldif

# Declarar administrador de LDAP
echo -e '1
' | ldapadd -x -D cn=admin,dc=debian,dc=asorc,dc=org -W -f ldapuser.ldif

# Crear un script para extraer usuarios de interés.
# (solo extraerá a ivan)
cat << 'EOF' > ldapuser.sh
# extract local users and groups who have [1000-9999] digit UID
# replace [SUFFIX=***] to your own domain name
# this is an example, free to modify

#!/bin/bash

SUFFIX='dc=debian,dc=asorc,dc=org'
LDIF='ldapuser.ldif'

echo -n > $LDIF
GROUP_IDS=()
grep "x:[1-9][0-9][0-9][0-9]:" /etc/passwd | (while read TARGET_USER
do
    USER_ID="$(echo "$TARGET_USER" | cut -d':' -f1)"

    USER_NAME="$(echo "$TARGET_USER" | cut -d':' -f5 | cut -d',' -f1 )"
    [ ! "$USER_NAME" ] && USER_NAME="$USER_ID"

    LDAP_SN="$(echo "$USER_NAME" | awk '{print $2}')"
    [ ! "$LDAP_SN" ] && LDAP_SN="$USER_ID"

    LASTCHANGE_FLAG="$(grep "${USER_ID}:" /etc/shadow | cut -d':' -f3)"
    [ ! "$LASTCHANGE_FLAG" ] && LASTCHANGE_FLAG="0"

    SHADOW_FLAG="$(grep "${USER_ID}:" /etc/shadow | cut -d':' -f9)"
    [ ! "$SHADOW_FLAG" ] && SHADOW_FLAG="0"

    GROUP_ID="$(echo "$TARGET_USER" | cut -d':' -f4)"
    [ ! "$(echo "${GROUP_IDS[@]}" | grep "$GROUP_ID")" ] && GROUP_IDS=("${GROUP_IDS[@]}" "$GROUP_ID")

    echo "dn: uid=$USER_ID,ou=people,$SUFFIX" >> $LDIF
    echo "objectClass: inetOrgPerson" >> $LDIF
    echo "objectClass: posixAccount" >> $LDIF
    echo "objectClass: shadowAccount" >> $LDIF
    echo "sn: $LDAP_SN" >> $LDIF
    echo "givenName: $(echo "$USER_NAME" | awk '{print $1}')" >> $LDIF
    echo "cn: $(echo "$USER_NAME" | awk '{print $1}')" >> $LDIF
    echo "displayName: $USER_NAME" >> $LDIF
    echo "uidNumber: $(echo "$TARGET_USER" | cut -d':' -f3)" >> $LDIF
    echo "gidNumber: $(echo "$TARGET_USER" | cut -d':' -f4)" >> $LDIF
    echo "userPassword: {crypt}$(grep "${USER_ID}:" /etc/shadow | cut -d':' -f2)" >> $LDIF
    echo "gecos: $USER_NAME" >> $LDIF
    echo "loginShell: $(echo "$TARGET_USER" | cut -d':' -f7)" >> $LDIF
    echo "homeDirectory: $(echo "$TARGET_USER" | cut -d':' -f6)" >> $LDIF
    echo "shadowExpire: $(passwd -S "$USER_ID" | awk '{print $7}')" >> $LDIF
    echo "shadowFlag: $SHADOW_FLAG" >> $LDIF
    echo "shadowWarning: $(passwd -S "$USER_ID" | awk '{print $6}')" >> $LDIF
    echo "shadowMin: $(passwd -S "$USER_ID" | awk '{print $4}')" >> $LDIF
    echo "shadowMax: $(passwd -S "$USER_ID" | awk '{print $5}')" >> $LDIF
    echo "shadowLastChange: $LASTCHANGE_FLAG" >> $LDIF
    echo >> $LDIF
done

for TARGET_GROUP_ID in "${GROUP_IDS[@]}"
do
    LDAP_CN="$(grep ":${TARGET_GROUP_ID}:" /etc/group | cut -d':' -f1)"

    echo "dn: cn=$LDAP_CN,ou=groups,$SUFFIX" >> $LDIF
    echo "objectClass: posixGroup" >> $LDIF
    echo "cn: $LDAP_CN" >> $LDIF
    echo "gidNumber: $TARGET_GROUP_ID" >> $LDIF

    for MEMBER_UID in $(grep ":${TARGET_GROUP_ID}:" /etc/passwd | cut -d':' -f1,3)
    do
        UID_NUM=$(echo "$MEMBER_UID" | cut -d':' -f2)
        [ $UID_NUM -ge 1000 -a $UID_NUM -le 9999 ] && echo "memberUid: $(echo "$MEMBER_UID" | cut -d':' -f1)" >> $LDIF
    done
    echo >> $LDIF
done
)
EOF

# Ejecutarlo
bash ldapuser.sh
echo '1
' | ldapadd -x -D cn=admin,dc=debian,dc=asorc,dc=org -W -f ldapuser.ldif

# Instala cliente
apt -y install libnss-ldapd libpam-ldapd ldap-utils
# ldapi:///192.168.25.10
# <Enter>
# Escoger:
# [*] passwd
# [*] group
# [*] shadow

# Configura PAM
echo -e "#
# /etc/pam.d/common-session - session-related modules common to all services
#
# This file is included from other service-specific PAM config files,
# and should contain a list of modules that define tasks to be performed
# at the start and end of interactive sessions.
#
# As of pam 1.0.1-6, this file is managed by pam-auth-update by default.
# To take advantage of this, it is recommended that you configure any
# local modules either before or after the default block, and use
# pam-auth-update to manage selection of other modules.  See
# pam-auth-update(8) for details.

# here are the per-package modules (the \"Primary\" block)
session [default=1]                     pam_permit.so
# here's the fallback if no module succeeds
session requisite                       pam_deny.so
# prime the stack with a positive return value if there isn't one already;
# this avoids us returning an error just because nothing sets a success code
# since the modules above will each just jump around
session required                        pam_permit.so
# reset the umask for new sessions
session optional                        pam_umask.so
# and here are more per-package modules (the \"Additional\" block)
session required        pam_unix.so
session optional                        pam_winbind.so
session [success=ok default=ignore]     pam_ldap.so minimum_uid=1000
session optional                        pam_wtmpdb.so skip_if=sshd
session optional        pam_systemd.so
# end of pam-auth-update config
session optional        pam_mkhomedir.so skel=/etc/skel umask=077
" > /etc/pam.d/common-session

# Aplica cambios
systemctl restart nscd nslcd

# Instala y configura el front para ldap
apt -y phpldapadmin
cat << 'EOF' > /etc/phpldapadmin/config.php
<?php
$config->custom->appearance['friendly_attrs'] = array(
 'facsimileTelephoneNumber' => 'Fax',
 'gid'                     => 'Group',
 'mail'                    => 'Email',
 'telephoneNumber'         => 'Telephone',
 'uid'                     => 'User Name',
 'userPassword'            => 'Password'
);
$servers = new Datastore();
$servers->newServer('ldap_pla');
$servers->setValue('server','name','My LDAP Server');
$servers->setValue('server','host','127.0.0.1');
$servers->setValue('server','base',array('dc=debian,dc=asorc,dc=org'));
$servers->setValue('login','auth_type','session');
$servers->setValue('login','bind_id','cn=admin,dc=debian,dc=asorc,dc=org');
$config->custom->session['reCAPTCHA-enable'] = false;
$config->custom->session['reCAPTCHA-key-site'] = '<put-here-key-site>';
$config->custom->session['reCAPTCHA-key-server'] = '<put-here-key-server>';
?>
EOF
