#!/bin/bash

###################################################
# NFS Y SAMBA                                     #
###################################################

CASA=/home/ivan
DESTINO=/memoria/linux/nfs_samba
DESTINO_L=$DESTINO/linux.log
DESTINO_H=$DESTINO/historylinux.txt
DESTINO_F=$DESTINO/configuration_files

rm -rf $DESTINO
mkdir -p $DESTINO
mkdir -p $DESTINO_F

cp /etc/exports $DESTINO_F/exports
cp /etc/samba/smb.conf $DESTINO_F/smb.conf

history > $DESTINO_H
journalctl -u nfs-kernel-server --no-pager > $DESTINO_L 2>/dev/null
journalctl -u smbd --no-pager >> $DESTINO_L 2>/dev/null
cat /var/log/samba/log.* >> $DESTINO_L 2>/dev/null
journalctl | grep -E "nfs|samba|smb|smbd" > $DESTINO_L