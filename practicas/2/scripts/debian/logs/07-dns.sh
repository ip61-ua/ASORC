#!/bin/bash

###################################################
# DNS                                             #
###################################################

CASA=/home/ivan
DESTINO=/memoria/linux/dns
DESTINO_L=$DESTINO/linux.log
DESTINO_H=$DESTINO/historylinux.txt
DESTINO_F=$DESTINO/configuration_files

rm -rf $DESTINO
mkdir -p $DESTINO
mkdir -p $DESTINO_F

cp /etc/bind/named.conf.options $DESTINO_F/named.conf.options
cp /etc/bind/named.conf.local $DESTINO_F/named.conf.local
cp /etc/bind/db.debian.asorc.org $DESTINO_F/db.debian.asorc.org
cp /etc/bind/db.192.168.25 $DESTINO_F/db.192.168.25
cp /etc/resolv.conf.head $DESTINO_F/resolv.conf.head
cp /etc/resolv.conf $DESTINO_F/resolv.conf

history > $DESTINO_H
journalctl -u bind9 --no-pager > $DESTINO_L 2>/dev/null
journalctl | grep -E "zone|bind9|named|/etc/bind|asorc|db\.192" >> $DESTINO_L

