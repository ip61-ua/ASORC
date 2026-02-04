#!/bin/sh

###################################################
# FreeNAS_iSCSI                                   #
###################################################

CASA=/home/ivan
DESTINO=/memoria/linux/FreeNAS_iSCSI
DESTINO_L=$DESTINO/linux.log
DESTINO_H=$DESTINO/historylinux.txt
DESTINO_F=$DESTINO/configuration_files

rm -rf $DESTINO
mkdir -p $DESTINO
mkdir -p $DESTINO_F

cp /etc/iscsi/iscsid.conf $DESTINO_F/iscsid.conf

history > $DESTINO_H
journalctl -u iscsitarget --no-pager > $DESTINO_L 2>/dev/null
journalctl -u open-iscsi --no-pager >> $DESTINO_L 2>/dev/null
journalctl | grep -E "iscsi|targetcli|ietd|open-iscsi|openiscsi|iscsiadm" >> $DESTINO_L