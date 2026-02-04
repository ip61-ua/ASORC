#!/bin/bash

###################################################
# LDAP                                            #
###################################################

CASA=/home/ivan
CASR=/root
DESTINO=/memoria/linux/ldap
DESTINO_L=$DESTINO/linux.log
DESTINO_H=$DESTINO/historylinux.txt
DESTINO_F=$DESTINO/configuration_files

rm -rf $DESTINO
mkdir -p $DESTINO
mkdir -p $DESTINO_F

cp $CASR/base.ldif $DESTINO_F/base.ldif
cp $CASR/ldapuser.ldif $DESTINO_F/ldapuser.ldif
cp $CASR/ldapuser.sh $DESTINO_F/ldapuser.sh
cp $CASR/etc/pam.d/common-session $DESTINO_F/common-session
cp /etc/phpldapadmin/config.php $DESTINO_F/config.php
cp /etc/php/8.4/apache2/php.init $DESTINO_F/php.init
cp /etc/hosts $DESTINO_F/hosts
cp /etc/ldap/ldap.conf $DESTINO_F/ldap.conf
slapcat > "$DESTINO_F/ldap_database_dump.txt" 2>/dev/null

history > $DESTINO_H
ournalctl -u slapd --no-pager > $DESTINO_L 2>/dev/null
journalctl -u apache2 --no-pager >> $DESTINO_L 2>/dev/null
cat /var/log/apache2/error.log >> $DESTINO_L 2>/dev/null
cat /var/log/apache2/access.log >> $DESTINO_L 2>/dev/null
journalctl --no-pager | grep -E "apache|a2en|a2dis|/var/www|php|ldap|slapd|ldif|phpldapadmin|ldapadd|ldappasswd" >> $DESTINO_L 2>/dev/null