#!/bin/sh
# setup_pxe_server.sh
# Descripción: Configura un servidor PXE/Instalación Desatendida FreeBSD
# Autor: Gemini para Usuario
# SO Servidor: FreeBSD 14.x

# --- Variables de Configuración ---
SERVER_IP="192.168.25.1"
GUEST_TARGET_IP="192.168.25.11"
DHCP_RANGE_START="192.168.25.101"
DHCP_RANGE_END="192.168.25.150"
DNS_SERVER="1.1.1.1"
WWW_ROOT="/usr/local/www/freebsd"
TFTP_ROOT="/usr/local/tftpboot"

echo ">>> Iniciando configuración del Servidor PXE en $SERVER_IP..."

# 1. Instalación de paquetes necesarios
echo ">>> Instalando dhcpd, tftp y nginx..."
pkg install -y isc-dhcp44-server tftp-hpa nginx wget

# 2. Configuración de Red del Servidor (Asegurar IP Host-Only)
# Nota: Asume que la interfaz host-only es la segunda (ej. em1). Ajustar según corresponda.
# sysrc ifconfig_em1="inet $SERVER_IP netmask 255.255.255.0"
# service netif restart

# 3. Configuración de DHCP (isc-dhcpd)
echo ">>> Configurando DHCP..."
cat <<EOF > /usr/local/etc/dhcpd.conf
option domain-name "pxe.local";
option domain-name-servers $DNS_SERVER, 8.8.8.8;

default-lease-time 600;
max-lease-time 7200;
log-facility local7;

subnet 192.168.25.0 netmask 255.255.255.0 {
  range $DHCP_RANGE_START $DHCP_RANGE_END;
  option routers $SERVER_IP;

  # Configuración PXE
  next-server $SERVER_IP;

  # Detección de Arquitectura (RFC 4578) para servir el loader correcto
  if option arch = 00:07 {
      filename "loader.efi";
  } else {
      filename "pxeboot";
  }
}
EOF

# Habilitar DHCP
sysrc dhcpd_enable="YES"
sysrc dhcpd_ifaces="em1" # AJUSTAR INTERFAZ

# 4. Configuración de TFTP
echo ">>> Configurando TFTP..."
mkdir -p $TFTP_ROOT
sysrc tftpd_enable="YES"
sysrc tftpd_flags="-l -s $TFTP_ROOT"

# Copiar bootloaders del sistema actual al TFTP (Asume que el host es FreeBSD amd64)
cp /boot/pxeboot $TFTP_ROOT/
cp /boot/loader.efi $TFTP_ROOT/

# 5. Configuración de HTTP (Nginx) y Estructura de Directorios
echo ">>> Configurando Nginx y Directorios de Distribución..."
mkdir -p $WWW_ROOT/releases/amd64/14.3-RELEASE
sysrc nginx_enable="YES"

# Configuración básica de Nginx
cat <<EOF > /usr/local/etc/nginx/nginx.conf
worker_processes  1;
events { worker_connections  1024; }
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
    server {
        listen       8069;
        server_name  localhost;
        root $WWW_ROOT;
        location / {
            autoindex on;
        }
    }
}
EOF

# NOTA: En un entorno real, aquí descargaríamos los .txz.
# Para el script, creamos archivos dummy si no existen para evitar errores de fetch largos
# cd $WWW_ROOT/releases/amd64/14.3-RELEASE
# fetch https://download.freebsd.org/releases/amd64/14.3-RELEASE/base.txz
# fetch https://download.freebsd.org/releases/amd64/14.3-RELEASE/kernel.txz
# fetch https://download.freebsd.org/releases/amd64/14.3-RELEASE/MANIFEST

# 6. Creación del script 'unattended.conf' (El corazón de la solicitud)
echo ">>> Generando script de instalación desatendida (unattended.conf)..."
cat <<EOF > $WWW_ROOT/unattended.conf
# --- Configuración de bsdinstall ---
PARTITIONS=DEFAULT
DISTRIBUTIONS="base.txz kernel.txz"

# Variable crítica para que bsdinstall sepa dónde buscar los paquetes sin preguntar
export BSDINSTALL_DISTSITE="http://$SERVER_IP:8069/releases/amd64/14.3-RELEASE"

#!/bin/sh
# --- Script Post-Instalación (chroot) ---

# A. Configuración de Red
# Adaptador 1 (NAT/WAN): DHCP
sysrc ifconfig_em0="DHCP"

# Adaptador 2 (Host-Only/LAN): IP Estática Solicitada
sysrc ifconfig_em1="inet $GUEST_TARGET_IP netmask 255.255.255.0"

# Hostname
sysrc hostname="guest-freebsd"

# B. Configuración de DNS
echo "nameserver $DNS_SERVER" > /etc/resolv.conf

# C. Habilitar SSH y permitir Root (para gestión inicial)
sysrc sshd_enable="YES"
sed -i '' 's/#PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config

# D. Usuario y Password
echo "FreeBSD123!" | pw usermod root -h 0

# E. Reiniciar
reboot
EOF

# 7. Reiniciar servicios
echo ">>> Reiniciando servicios..."
service isc-dhcpd restart
service inetd restart # Si TFTP corre vía inetd, o service tftpd restart
service nginx restart

echo ">>> Configuración completada."
echo ">>> Asegúrese de que los archivos base.txz y kernel.txz estén en $WWW_ROOT/releases/amd64/14.3-RELEASE"
