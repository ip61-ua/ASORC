#!/bin/bash

###################################################
# GIT+NEXTCLOUD                                   #
###################################################

CASA=/home/ivan
DESTINO=/memoria/linux/git_nextcloud
DESTINO_L=$DESTINO/linux.log
DESTINO_H=$DESTINO/historylinux.txt
DESTINO_F=$DESTINO/configuration_files

rm -rf $DESTINO
mkdir -p $DESTINO
mkdir -p $DESTINO_F

cp -r /srv/git/practica.git $DESTINO_F/practica.git
cp /etc/php/8.4/apache2/php.init $DESTINO_F/php.init
cp /etc/apache2/sites-available/nextcloud.conf $DESTINO_F/nextcloud.conf
cp /var/www/html/nextcloud/config/config.php $DESTINO_F/config.php
cp /etc/hosts $DESTINO_F/hosts

history > $DESTINO_H
journalctl -u sshd --no-pager | grep -E 'git-receive-pack|git-upload-pack' > $DESTINO_L 2>/dev/null
journalctl | grep -E "git|/srv/git" >> $DESTINO_L  2>/dev/null
journalctl -u apache2 --no-pager >> $DESTINO_L 2>/dev/null
cat /var/log/apache2/error.log >> $DESTINO_L 2>/dev/null
cat /var/log/apache2/access.log >> $DESTINO_L 2>/dev/null
cat /var/log/apache2/nextdebian.org-error.log >> $DESTINO_L 2>/dev/null
cat /var/log/apache2/nextdebian.org-access.log >> $DESTINO_L 2>/dev/null
journalctl --no-pager | grep -E "apache|a2en|a2dis|/var/www|php|nextcloud" >> $DESTINO_L 2>/dev/null
