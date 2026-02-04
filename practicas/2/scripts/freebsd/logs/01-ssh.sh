#!/bin/bash

###################################################
# SSH                                             #
###################################################

CASA=/home/ivan
DESTINO=/memoria/unix/ssh
DESTINO_L=$DESTINO/unix.log
DESTINO_H=$DESTINO/historyunix.txt
DESTINO_F=$DESTINO/configuration_files

rm -rf $DESTINO
mkdir -p $DESTINO
mkdir -p $DESTINO_F

cp $CASA/.ssh/id_rsa.pub $DESTINO_F/id_rsa.pub
cp $CASA/.ssh/authorized_keys $DESTINO_F/authorized_keys
cp /etc/ssh/sshd_config $DESTINO_F/sshd_config
cp /etc/ssh/ssh_host_ed25519_key.pub $DESTINO_F/ssh_host_ed25519_key.pub
cp /etc/ssh/ssh_host_rsa_key.pub $DESTINO_F/ssh_host_rsa_key.pub
cp /etc/ssh/ssh_host_ecdsa_key.pub $DESTINO_F/ssh_host_ecdsa_key.pub

history > $DESTINO_H
grep -E "tigervnc|tiger|vnc|x11vnc|xrdp|rdp|sesman|xrdp-sesman" /var/log/ > $DESTINO_L