#!/bin/sh
su -

#-------------------------------------------------------
# Variables de entorno
#-------------------------------------------------------
P3ASORC_SERVICIO=wol
P3ASORC_SISTEMA=linux

# NO TOCAR
P3ASORC_MEMORIA=/home/ivan/SUPERMEMORIA/$P3ASORC_SERVICIO
P3ASORC_CONFIG=$P3ASORC_MEMORIA/ficheros_configuracion
P3ASORC_LOG=$P3ASORC_MEMORIA/$P3ASORC_SISTEMA.log
P3ASORC_HISTORIAL=$P3ASORC_MEMORIA/history$P3ASORC_SISTEMA.txt

# --- VARIABLES ESPECIFICAS WOL / DESATENDIDA ---
P3ASORC_WOL_IFACE=enp0s8
P3ASORC_WOL_IP=192.168.25.10
P3ASORC_WOL_MASK=255.255.255.0
P3ASORC_WOL_RANGO_INI=192.168.25.50
P3ASORC_WOL_RANGO_FIN=192.168.25.100
P3ASORC_WOL_DNS=1.1.1.1
P3ASORC_WOL_TFTP_DIR=/var/lib/tftpboot
P3ASORC_WOL_WEB_DIR=/var/www/html
# URL del instalador de red de Debian 13
P3ASORC_WOL_URL_DEBIAN=http://ftp.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/debian-installer/amd64

# Rutas de configuracion
P3ASORC_GRUPO_CONFIG_DHCP=/etc/dhcp/dhcpd.conf
P3ASORC_GRUPO_CONFIG_TFTP=/etc/default/tftpd-hpa
P3ASORC_GRUPO_CONFIG_PXE=$P3ASORC_WOL_TFTP_DIR/pxelinux.cfg/default

#-------------------------------------------------------
# Servicio (no backtrack)
#-------------------------------------------------------

# PASO 1: Instalar paquetes (Añadido etherwake y apache2)
# apache2 servira el fichero preseed.cfg, etherwake hace el WOL
apt update
apt install -y isc-dhcp-server tftpd-hpa pxelinux syslinux-common wget psmisc etherwake apache2

# Limpieza de procesos previos
systemctl stop isc-dhcp-server
systemctl stop tftpd-hpa
systemctl stop apache2

# Liberar puertos por seguridad
fuser -k -v 67/udp || echo "Puerto 67 limpio"
fuser -k -v 69/udp || echo "Puerto 69 limpio"
fuser -k -v 80/tcp || echo "Puerto 80 limpio"

# Asegurar directorios y permisos
mkdir -p $P3ASORC_WOL_TFTP_DIR
chown -R tftp:tftp $P3ASORC_WOL_TFTP_DIR
chmod -R 777 $P3ASORC_WOL_TFTP_DIR

# Iniciar servicios base
systemctl start isc-dhcp-server
systemctl start tftpd-hpa
systemctl start apache2

# PASO 2: Configurar interfaz DHCP
sed -i 's/^INTERFACESv4=.*/INTERFACESv4="'$P3ASORC_WOL_IFACE'"/' /etc/default/isc-dhcp-server

# PASO 3: Configurar DHCPD
cat > $P3ASORC_GRUPO_CONFIG_DHCP <<EOF
option domain-name "pxewol.local";
option domain-name-servers $P3ASORC_WOL_DNS;
default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet 192.168.25.0 netmask $P3ASORC_WOL_MASK {
  range $P3ASORC_WOL_RANGO_INI $P3ASORC_WOL_RANGO_FIN;
  option routers $P3ASORC_WOL_IP;
  next-server $P3ASORC_WOL_IP;
  filename "pxelinux.0";
}
EOF

# PASO 4: Configurar TFTP y Syslinux
sed -i 's|TFTP_DIRECTORY=.*|TFTP_DIRECTORY="'$P3ASORC_WOL_TFTP_DIR'"|' $P3ASORC_GRUPO_CONFIG_TFTP
mkdir -p $P3ASORC_WOL_TFTP_DIR/pxelinux.cfg
cp /usr/lib/PXELINUX/pxelinux.0 $P3ASORC_WOL_TFTP_DIR/
cp /usr/lib/syslinux/modules/bios/ldlinux.c32 $P3ASORC_WOL_TFTP_DIR/
cp /usr/lib/syslinux/modules/bios/menu.c32 $P3ASORC_WOL_TFTP_DIR/
cp /usr/lib/syslinux/modules/bios/libutil.c32 $P3ASORC_WOL_TFTP_DIR/

# PASO 5: Descargar Instalador Debian (Netboot)
mkdir -p $P3ASORC_WOL_TFTP_DIR/debian-installer
echo "Descargando kernel e initrd de Debian..."
wget -O $P3ASORC_WOL_TFTP_DIR/debian-installer/linux $P3ASORC_WOL_URL_DEBIAN/linux
wget -O $P3ASORC_WOL_TFTP_DIR/debian-installer/initrd.gz $P3ASORC_WOL_URL_DEBIAN/initrd.gz

# PASO 6: Crear Fichero Preseed (Instalacion Desatendida)
# Este fichero automatiza las preguntas del instalador.
cat > /etc/apache2/sites-available/000-default.conf <<EOF
<VirtualHost *:80>
    ServerAdmin dbdebian.org
    DocumentRoot /var/www/html
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

mkdir -p $P3ASORC_WOL_WEB_DIR
chown -R www-data:www-data $P3ASORC_WOL_WEB_DIR
chmod 755 $P3ASORC_WOL_WEB_DIR

mkdir -p /etc/apache2/sites-enabled
ln -sf /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-enabled/000-default.conf

rm -f $P3ASORC_WOL_WEB_DIR/preseed.cfg
cat > $P3ASORC_WOL_WEB_DIR/preseed.cfg <<EOF
# --- Localizacion ---
d-i debian-installer/locale string es_ES
d-i keyboard-configuration/xkb-keymap select es

# --- Red y DNS ---
d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string debian-pxe
d-i netcfg/get_domain string local
# CAMBIO: Forzar DNS 1.1.1.1
d-i netcfg/get_nameservers string 1.1.1.1

# --- Espejo ---
d-i mirror/country string manual
d-i mirror/http/hostname string ftp.es.debian.org
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string

# --- Cuentas (root/root y usuario/usuario) ---
d-i passwd/root-login boolean true
d-i passwd/root-password password root
d-i passwd/root-password-again password root
d-i passwd/make-user boolean true
d-i passwd/user-fullname string Usuario PXE
d-i passwd/username string usuario
d-i passwd/user-password password usuario
d-i passwd/user-password-again password usuario

# --- Particionado ---
d-i partman-auto/method string regular
d-i partman-auto/choose_recipe select atomic
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

# --- Finalizar ---
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i grub-installer/bootdev string /dev/sda
d-i finish-install/reboot_in_progress not
EOF

# Ajustar permisos para que Apache pueda leerlo
chmod 644 $P3ASORC_WOL_WEB_DIR/preseed.cfg
chown www-data:www-data $P3ASORC_WOL_WEB_DIR/preseed.cfg

# Permisos lectura web
chmod 644 $P3ASORC_WOL_WEB_DIR/preseed.cfg

# PASO 7: Crear Menu PXE con opcion Desatendida
rm -f $P3ASORC_GRUPO_CONFIG_PXE
cat > $P3ASORC_GRUPO_CONFIG_PXE <<EOF
DEFAULT menu.c32
PROMPT 0
TIMEOUT 100
MENU TITLE Bienvenido al menu de arranque por red de Debian 13!

LABEL install_auto
  MENU LABEL ^1) Instalar Debian (Desatendido) (item 11)
  KERNEL debian-installer/linux
  APPEND initrd=debian-installer/initrd.gz auto=true priority=critical url=http://$P3ASORC_WOL_IP/preseed.cfg interface=auto

LABEL slitaz
  MENU LABEL ^2) Thin Client Grafico (SliTaz Rolling) (item 10)
  KERNEL slitaz/vmlinuz
  APPEND initrd=slitaz/initrd.gz rw root=/dev/null autologin
EOF

# PASO 8: Reiniciar servicios
systemctl restart isc-dhcp-server
systemctl restart tftpd-hpa
systemctl restart apache2

# PASO 9: NAT
echo 1 > /proc/sys/net/ipv4/ip_forward
# Configurar IPTables para que haga de "puente" (NAT)
# Todo lo que venga de la red interna, que salga por la de internet (enp0s8)
# Asegurarse que enp0s8 es la que tiene internet. Si es al revés, cambia enp0s8 por enp0s3.
iptables -t nat -A POSTROUTING -o enp0s8 -j MASQUERADE

# Aceptar tráfico de reenvío
iptables -A FORWARD -i enp0s8 -o enp0s3 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i enp0s3 -o enp0s8 -j ACCEPT

#-------------------------------------------------------
# Valida servicio
#-------------------------------------------------------
systemctl status isc-dhcp-server --no-pager
systemctl status apache2 --no-pager
# Comprobar que el preseed es accesible via web
curl -I http://localhost/preseed.cfg
ls -l $P3ASORC_WOL_TFTP_DIR/debian-installer/

#-------------------------------------------------------
# Extraer logs, configs e historial
#-------------------------------------------------------
rm -rf $P3ASORC_MEMORIA
mkdir -p $P3ASORC_MEMORIA
mkdir -p $P3ASORC_CONFIG

cp $P3ASORC_GRUPO_CONFIG_DHCP $P3ASORC_CONFIG/dhcpd.conf
cp $P3ASORC_GRUPO_CONFIG_TFTP $P3ASORC_CONFIG/tftpd-hpa
cp $P3ASORC_WOL_WEB_DIR/preseed.cfg $P3ASORC_CONFIG/preseed.cfg

systemctl status --no-pager -l isc-dhcp-server > $P3ASORC_LOG
systemctl status --no-pager -l apache2 >> $P3ASORC_LOG

history > $P3ASORC_HISTORIAL
chmod 777 -R $P3ASORC_MEMORIA

tree $P3ASORC_MEMORIA

#-------------------------------------------------------
# Comprobacion desde host
#-------------------------------------------------------
# 1. Preparacion:
#    - Apaga la VM Cliente.
#    - En VirtualBox/VMware, asegurate que la MAC del cliente es conocida.
#    - Configura la BIOS del cliente para aceptar Wake On LAN.

# 2. Despertar al cliente (WOL):
#    - Desde este servidor (Debian), ejecuta:
#    etherwake -i enp0s8 08:00:00:00:00:10
#    etherwake 08:00:00:00:00:10
#    wakeonlan 08:00:00:00:00:10

# 3. Instalacion:
#    - El cliente deberia encenderse solo.
#    - Cargara el menu PXE.
#    - Selecciona "Instalar Debian".
#    - No toques nada. Deberia particionar e instalarse solo (password root: root).

