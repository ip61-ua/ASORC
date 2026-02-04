#!/bin/bash

###################################################
# WEB                                             #
###################################################

CASA=/home/ivan
DESTINO=/memoria/linux/web
DESTINO_L=$DESTINO/linux.log
DESTINO_H=$DESTINO/historylinux.txt
DESTINO_F=$DESTINO/configuration_files

rm -rf $DESTINO
mkdir -p $DESTINO
mkdir -p $DESTINO_F

cp /etc/php/8.4/apache2/php.init $DESTINO_F/php.init
cp /etc/apache2/sites-available/wordpress.conf $DESTINO_F/wordpress.conf
cp /etc/apache2/sites-available/grav.conf $DESTINO_F/grav.conf
cp /etc/hosts $DESTINO_F/hosts

history > $DESTINO_H
journalctl -u apache2 --no-pager > $DESTINO_L 2>/dev/null
cat /var/log/apache2/error.log >> $DESTINO_L 2>/dev/null
cat /var/log/apache2/access.log >> $DESTINO_L 2>/dev/null
cat /var/log/apache2/web1debian.org_error.log >> $DESTINO_L 2>/dev/null
cat /var/log/apache2/web1debian.org_access.log >> $DESTINO_L 2>/dev/null
cat /var/log/apache2/web2debian.org_error.log >> $DESTINO_L 2>/dev/null
cat /var/log/apache2/web2debian.org_access.log >> $DESTINO_L 2>/dev/null
journalctl --no-pager | grep -E "apache|a2en|a2dis|/var/www|php|wordpress|grav" >> $DESTINO_L 2>/dev/null
