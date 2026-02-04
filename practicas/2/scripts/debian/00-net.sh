#!/bin/bash

# Sobrescribe el fichero de configuración de interfaces de red
# - Configura la interfaz enp0s3 (NAT) para que obtenga IP por DHCP
# - Configura la interfaz enp0s8 (Host-Only) con una IP estática
# - Establece un servidor DNS (Cloudflare) de forma persistente
echo "# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).
source /etc/network/interfaces.d/*
auto lo enp0s3 enp0s8
iface lo inet loopback
iface enp0s3 inet dhcp
iface enp0s8 inet static
address 192.168.25.10
broadcast 192.168.25.255
netmask 255.255.255.0" > /etc/network/interfaces
echo "nameserver 1.1.1.1" > /etc/resolv.conf.tail
# Reinicia el servicio de red para aplicar todos los cambios
systemctl restart networking

# Hacer accesibles páginas de Debian
cat << 'EOF' > /etc/hosts
127.0.0.1       nextdebian.org dbdebian.org web1debian.org web2debian.org
127.0.0.1       localhost
127.0.1.1       debian.debian.asorc.org debian

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF