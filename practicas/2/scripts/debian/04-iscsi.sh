#!/bin/sh

# Instala y habilita servicio
apt install -y open-iscsi
systemctl start open-iscsi

# Descubrir
iscsiadm -m discovery -t st -p 192.168.25.9

# Conectarse
# AAAAA = iqn.2005-10.org.freenas.ctl:servidor-iscsi o similar
sudo iscsiadm -m node -T AAAAA -p 192.168.25.9 -l

# Ver bloques
lsblk