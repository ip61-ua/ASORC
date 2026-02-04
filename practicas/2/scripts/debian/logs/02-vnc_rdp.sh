#!/bin/bash

###################################################
# VNC y RDP                                       #
###################################################

CASA=/home/ivan
DESTINO=/memoria/linux/vnc_rdp
DESTINO_L=$DESTINO/linux.log
DESTINO_H=$DESTINO/historylinux.txt
DESTINO_F=$DESTINO/configuration_files

rm -rf $DESTINO
mkdir -p $DESTINO
mkdir -p $DESTINO_F
mkdir -p $DESTINO_F$CASA

cp ~/start-vnc.sh $DESTINO_F/start-vnc.sh
cp $CASA/start-vnc.sh $DESTINO_F$CASA/start-vnc.sh
cp /etc/tigervnc/vncserver.users $DESTINO_F/vncserver.users
cp ~/start-vnc.sh $DESTINO_F/start-vnc.sh
cp ~/.xsession $DESTINO_F/.xsession
cp $CASA/.xsession $DESTINO_F$CASA/.xsession
cp /etc/xrdp/sesman.ini $DESTINO_F/sesman.ini

journalctl | grep -E "tigervnc|tiger|vnc|x11vnc|xrdp|rdp|sesman|xrdp-sesman" > $DESTINO_L
history > $DESTINO_H