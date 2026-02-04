#!/bin/bash

###################################################
# DNS                                             #
###################################################

CASA=/home/ivan
DESTINO=/memoria/unix/dns
DESTINO_L=$DESTINO/unix.log
DESTINO_H=$DESTINO/historyunix.txt
DESTINO_F=$DESTINO/configuration_files

rm -rf $DESTINO
mkdir -p $DESTINO
mkdir -p $DESTINO_F

cp /usr/local/etc/namedb/named.conf $DESTINO_F/named.conf
cp /usr/local/etc/namedb/internal-zones.conf $DESTINO_F/internal-zones.conf
cp /usr/local/etc/namedb/primary/db.bsd.asorc.org $DESTINO_F/db.bsd.asorc.org
cp /usr/local/etc/namedb/primary/db.192.168.25 $DESTINO_F/db.192.168.25
cp /etc/rc.conf $DESTINO_F/rc.conf
cp /etc/resolv.conf.bk $DESTINO_F/resolv.conf.bk
cp /etc/resolv.conf $DESTINO_F/resolv.conf

history > $DESTINO_H
grep -R "name" /var/log/* > $DESTINO_L
grep -R "bind" /var/log/* >> $DESTINO_L

