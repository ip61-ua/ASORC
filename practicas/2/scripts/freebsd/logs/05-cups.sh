#!/bin/bash

###################################################
# CUPS                                            #
###################################################

CASA=/home/ivan
DESTINO=/memoria/unix/cups
DESTINO_L=$DESTINO/unix.log
DESTINO_H=$DESTINO/historyunix.txt
DESTINO_F=$DESTINO/configuration_files

rm -rf $DESTINO
mkdir -p $DESTINO
mkdir -p $DESTINO_F

cp /etc/rc.conf $DESTINO_F/rc.conf
cp /usr/local/etc/cups/cupsd.conf $DESTINO_F/cupsd.conf
cp /usr/local/etc/cups/cups-pdf.conf $DESTINO_F/cups-pdf.conf
cp /etc/devfs.rules $DESTINO_F/devfs.rules

history > $DESTINO_H
tail /var/log/cups/* >> $DESTINO_L 2>/dev/null