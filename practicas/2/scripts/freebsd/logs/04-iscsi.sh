#!/bin/sh

###################################################
# FreeNAS_iSCSI                                   #
###################################################

CASA=/home/ivan
DESTINO=/memoria/unix/FreeNAS_iSCSI
DESTINO_L=$DESTINO/unix.log
DESTINO_H=$DESTINO/historyunix.txt
DESTINO_F=$DESTINO/configuration_files

rm -rf $DESTINO
mkdir -p $DESTINO
mkdir -p $DESTINO_F

cp /etc/iscsi.conf $DESTINO_F/iscsid.conf

history > $DESTINO_H
grep -R 'iscsi' /var/log > $DESTINO_L
grep -R 'targetcli' /var/log >> $DESTINO_L
grep -R 'ietd' /var/log >> $DESTINO_L
grep -R 'iscsictl' /var/log >> $DESTINO_L
grep -R 'open-iscsi' /var/log >> $DESTINO_L
grep -R 'openiscsi' /var/log >> $DESTINO_L
grep -R 'iscsitarget' /var/log >> $DESTINO_L