#!/bin/bash

###################################################
# VNC y RDP                                       #
###################################################

CASA=/home/ivan
DESTINO=/memoria/unix/vnc_rdp
DESTINO_L=$DESTINO/unix.log
DESTINO_H=$DESTINO/historyunix.txt
DESTINO_F=$DESTINO/configuration_files

rm -rf $DESTINO
mkdir -p $DESTINO
mkdir -p $DESTINO_F

cp $CASA/.vnc/passwd $DESTINO_F/passwd
cp $CASA/.vnc/config $DESTINO_F/config
cp $CASA/startwm.sh $DESTINO_F/startwm.sh
cp /usr/local/etc/xrdp/xrdp.ini $DESTINO_F/xrdp.ini
cp ~/.xsession $DESTINO_F/.xsession
cp $CASA/.xsession $DESTINO_F$CASA/.xsession

cat .vnc/bsd.asorc.org:1.log > $DESTINO_L
grep -R "tigervnc" /var/log/ >> $DESTINO_L
grep -R "vnc" /var/log/ >> $DESTINO_L
grep -R "sesman" /var/log/ >> $DESTINO_L
grep -R "rdp" /var/log/ >> $DESTINO_L
grep -R "xrdp" /var/log/ >> $DESTINO_L
grep -R "xrdp-sesman" /var/log/ >> $DESTINO_L
cat $CASA/vnc_rdp.0.hist > $DESTINO_H
cat $CASA/vnc_rdp.1.hist >> $DESTINO_H
cat $CASA/vnc_rdp.2.hist >> $DESTINO_H
history >> $DESTINO_H