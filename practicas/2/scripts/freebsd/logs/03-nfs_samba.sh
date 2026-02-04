#!/bin/bash

###################################################
# NFS Y SAMBA                                     #
###################################################

CASA=/home/ivan
DESTINO=/memoria/unix/nfs_samba
DESTINO_L=$DESTINO/unix.log
DESTINO_H=$DESTINO/historyunix.txt
DESTINO_F=$DESTINO/configuration_files

rm -rf $DESTINO
mkdir -p $DESTINO
mkdir -p $DESTINO_F

cp /etc/rc.conf $DESTINO_F/rc.conf
cp /etc/exports $DESTINO_F/exports
cp /usr/local/etc/smb4.conf $DESTINO_F/smb4.conf

history > $DESTINO_H
grep -R "nfs" /var/log > $DESTINO_L
grep -R "samba" /var/log >> $DESTINO_L
grep -R "smb" /var/log >> $DESTINO_L
grep -R "smbd" /var/log >> $DESTINO_L
cat /var/log/samba4/log.* >> $DESTINO_L 2>/dev/null