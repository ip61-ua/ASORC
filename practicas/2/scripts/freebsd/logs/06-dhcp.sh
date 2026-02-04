#!/bin/bash

###################################################
# DHCP                                            #
###################################################

CASA=/home/ivan
DESTINO=/memoria/unix/dhcp
DESTINO_L=$DESTINO/unix.log
DESTINO_H=$DESTINO/historyunix.txt
DESTINO_F=$DESTINO/configuration_files

rm -rf $DESTINO
mkdir -p $DESTINO
mkdir -p $DESTINO_F

cp /etc/rc.conf $DESTINO_F/rc.conf
cp /usr/local/etc/dhcpd.conf $DESTINO_F/dhcpd.conf

history > $DESTINO_H
cat /var/log/dhcpd.log > $DESTINO_L