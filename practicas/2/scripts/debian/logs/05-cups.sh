#!/bin/bash

###################################################
# CUPS                                            #
###################################################

CASA=/home/ivan
DESTINO=/memoria/linux/cups
DESTINO_L=$DESTINO/linux.log
DESTINO_H=$DESTINO/historylinux.txt
DESTINO_F=$DESTINO/configuration_files

rm -rf $DESTINO
mkdir -p $DESTINO
mkdir -p $DESTINO_F

cp /etc/cups/cupsd.conf $DESTINO_F/cupsd.conf
cp /etc/cups/cups-pdf.conf $DESTINO_F/cups-pdf.conf

history > $DESTINO_H
journalctl -u cups --no-pager > $DESTINO_L 2>/dev/null
cat /var/log/cups/error_log >> $DESTINO_L 2>/dev/null
journalctl | grep -E "cups|lpadmin" >> $DESTINO_L