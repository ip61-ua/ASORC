#!/bin/bash

###################################################
# DHCP                                            #
###################################################

CASA=/home/ivan
DESTINO=/memoria/linux/dhcp
DESTINO_L=$DESTINO/linux.log
DESTINO_H=$DESTINO/historylinux.txt
DESTINO_F=$DESTINO/configuration_files

rm -rf $DESTINO
mkdir -p $DESTINO
mkdir -p $DESTINO_F

cp /etc/default/isc-dhcp-server $DESTINO_F/isc-dhcp-server
cp /etc/dhcp/dhcpd.conf $DESTINO_F/dhcpd.conf

history > $DESTINO_H
journalctl -u isc-dhcp-server --no-pager > $DESTINO_L 2>/dev/null
journalctl | grep -E "dhcp|isc-dhcp|dhcpd.conf|isc-dhcp-server" >> $DESTINO_L