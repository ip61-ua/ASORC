#!/bin/sh
# Configuración
echo 'target01 {
    targetaddress = 192.168.25.9;
}' > /etc/iscsi.conf

# Habilita servicio
sysrc iscsid_enable="YES"
sysrc iscsictl_enable="YES"
service iscsid start

# Descubrir
iscsictl -A -d 192.168.25.9 -w 7
iscsictl -L

# Conectarse
iscsictl -A -p 192.168.25.9 -t iqn.2005-10.org.freenas.ctl:todos

# Montaje y expulsión
mkdir -p /home/ivan/mi_disco
mount -t msdosfs /dev/da0s1 /home/ivan/mi_disco
umount /home/ivan/mi_disco

# Desconectarse
iscsictl -R -p 192.168.25.9 -t iqn.2005-10.org.freenas.ctl:todos