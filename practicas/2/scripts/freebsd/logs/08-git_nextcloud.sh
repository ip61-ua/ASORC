#!/bin/bash

###################################################
# GIT+NEXTCLOUD                                   #
###################################################

CASA=/home/ivan
DESTINO=/memoria/unix/git_nextcloud
DESTINO_L=$DESTINO/unix.log
DESTINO_H=$DESTINO/historyunix.txt
DESTINO_F=$DESTINO/configuration_files

rm -rf $DESTINO
mkdir -p $DESTINO
mkdir -p $DESTINO_F

cp -r /var/srv/git/practica2.git $DESTINO_F/practica2.git
cp /usr/local/etc/apache24/httpd.conf $DESTINO_F/httpd.conf
cp /usr/local/etc/php-fpm.d/www.conf $DESTINO_F/www.conf
cp /usr/local/etc/apache24/extra/httpd-ssl.conf $DESTINO_F/httpd-ssl.conf
cp /etc/hosts $DESTINO_F/hosts
cp /usr/local/etc/mysql/conf.d/server.cnf $DESTINO_F/server.cnf
cp /usr/local/etc/php-fpm.d/nextcloud.conf $DESTINO_F/phpnextcloud.conf
cp /usr/local/etc/apache24/Includes/nextcloud.conf  $DESTINO_F/nextcloud.conf
cp /var/www/html/nextcloud/config/config.php $DESTINO_F/config.php

history > $DESTINO_H
cat /var/log/redis/redis.log > $DESTINO_L
cat /var/log/mysql/mysqld.err >> $DESTINO_L
cat /var/log/httpd-* >> $DESTINO_L
cat /var/log/php-fpm.log >> $DESTINO_L