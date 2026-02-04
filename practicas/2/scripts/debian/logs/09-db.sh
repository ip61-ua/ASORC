#!/bin/bash

###################################################
# DB                                              #
###################################################

CASA=/home/ivan
DESTINO=/memoria/linux/bd
DESTINO_L=$DESTINO/linux.log
DESTINO_H=$DESTINO/historylinux.txt
DESTINO_F=$DESTINO/configuration_files

rm -rf $DESTINO
mkdir -p $DESTINO
mkdir -p $DESTINO_F

cp /etc/php/8.4/apache2/php.init $DESTINO_F/php.init
cp /etc/apache2/sites-available/db.conf $DESTINO_F/db.conf
cp /etc/hosts $DESTINO_F/hosts
cp /var/www/db/index.php $DESTINO_F/index.php

history > $DESTINO_H
journalctl --no-pager | grep -E 'mysql|mariadb|maria|sql' > $DESTINO_L 2>/dev/null
journalctl -u apache2 --no-pager >> $DESTINO_L 2>/dev/null
cat /var/log/apache2/error.log >> $DESTINO_L 2>/dev/null
cat /var/log/apache2/access.log >> $DESTINO_L 2>/dev/null
cat /var/log/apache2/dbdebian.org-error.log >> $DESTINO_L 2>/dev/null
cat /var/log/apache2/dbdebian.org-access.log >> $DESTINO_L 2>/dev/null
