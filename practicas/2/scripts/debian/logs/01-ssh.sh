#!/bin/bash

###################################################
# SSH                                             #
###################################################

CASA=/home/ivan
DESTINO=/memoria/linux/ssh
DESTINO_L=$DESTINO/linux.log
DESTINO_H=$DESTINO/historylinux.txt
DESTINO_F=$DESTINO/configuration_files

rm -rf $DESTINO
mkdir -p $DESTINO
mkdir -p $DESTINO_F

cp $CASA/.ssh/id_rsa.pub $DESTINO_F/id_rsa.pub
cp $CASA/.ssh/authorized_keys $DESTINO_F/authorized_keys
cp /etc/ssh/sshd_config $DESTINO_F/sshd_config
cp /etc/ssh/sshd_config.d/personalizar.conf $DESTINO_F/sshd_config.d/personalizar.conf

history > $DESTINO_H
grep -R "ssh" /var/log/ > $DESTINO_L