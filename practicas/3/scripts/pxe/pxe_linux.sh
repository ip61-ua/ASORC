#!/bin/sh
su -

#-------------------------------------------------------
# Variables de entorno
#-------------------------------------------------------
P3ASORC_SERVICIO=pxe
P3ASORC_SISTEMA=linux

# NO TOCAR
P3ASORC_MEMORIA=/home/ivan/SUPERMEMORIA/$P3ASORC_SERVICIO
P3ASORC_CONFIG=$P3ASORC_MEMORIA/ficheros_configuracion
P3ASORC_LOG=$P3ASORC_MEMORIA/$P3ASORC_SISTEMA.log
P3ASORC_HISTORIAL=$P3ASORC_MEMORIA/history$P3ASORC_SISTEMA.txt

# --- VARIABLES ESPECIFICAS PXE ---
P3ASORC_PXE_IFACE=enp0s8
P3ASORC_PXE_IP=192.168.25.10
P3ASORC_PXE_MASK=255.255.255.0
P3ASORC_PXE_RANGO_INI=192.168.25.50
P3ASORC_PXE_RANGO_FIN=192.168.25.100
P3ASORC_PXE_DNS=1.1.1.1
P3ASORC_PXE_TFTP_DIR=/var/lib/tftpboot
# Usamos SliTaz Rolling: ~50MB con entorno grafico LXDE/Openbox incluido en el initrd
P3ASORC_PXE_URL_ISO=http://mirror.slitaz.org/iso/rolling/slitaz-rolling.iso

# Rutas de configuracion para backup
P3ASORC_GRUPO_CONFIG_DHCP=/etc/dhcp/dhcpd.conf
P3ASORC_GRUPO_CONFIG_TFTP=/etc/default/tftpd-hpa
P3ASORC_GRUPO_CONFIG_PXE=$P3ASORC_PXE_TFTP_DIR/pxelinux.cfg/default

#-------------------------------------------------------
# Servicio (no backtrack)
#-------------------------------------------------------

# PASO 1: Instalar paquetes y limpieza profunda de puertos
apt update
apt install -y isc-dhcp-server tftpd-hpa pxelinux syslinux-common wget psmisc

# Detener servicios para asegurar configuracion limpia
systemctl stop isc-dhcp-server
systemctl stop tftpd-hpa
systemctl stop inetd 2>/dev/null || true
systemctl stop xinetd 2>/dev/null || true

# Matar procesos huerfanos en puertos criticos (67 UDP, 69 UDP, 53 TCP/UDP)
echo "Liberando puertos..."
fuser -k -v 67/udp || echo "Puerto 67 OK"
fuser -k -v 69/udp || echo "Puerto 69 OK"
fuser -k -v 53/tcp || echo "Puerto 53 OK"

# Crear directorio antes de asignar permisos
mkdir -p $P3ASORC_PXE_TFTP_DIR
chown -R tftp:tftp $P3ASORC_PXE_TFTP_DIR
chmod -R 777 $P3ASORC_PXE_TFTP_DIR

# Iniciamos los servicios limpios
systemctl start isc-dhcp-server
systemctl start tftpd-hpa

# PASO 2: Configurar interfaz de escucha DHCP
# Vinculamos DHCP solo a la interfaz Host-Only
sed -i 's/^INTERFACESv4=.*/INTERFACESv4="'$P3ASORC_PXE_IFACE'"/' /etc/default/isc-dhcp-server

# PASO 3: Configurar DHCPD
# Definimos la subred y apuntamos al fichero de arranque
cat > $P3ASORC_GRUPO_CONFIG_DHCP <<EOF
option domain-name "pxelab.local";
option domain-name-servers $P3ASORC_PXE_DNS;
default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet 192.168.25.0 netmask $P3ASORC_PXE_MASK {
  range $P3ASORC_PXE_RANGO_INI $P3ASORC_PXE_RANGO_FIN;
  option routers $P3ASORC_PXE_IP;
  next-server $P3ASORC_PXE_IP;
  filename "pxelinux.0";
}
EOF

# PASO 4: Configurar TFTP y Syslinux
sed -i 's|TFTP_DIRECTORY=.*|TFTP_DIRECTORY="'$P3ASORC_PXE_TFTP_DIR'"|' $P3ASORC_GRUPO_CONFIG_TFTP
mkdir -p $P3ASORC_PXE_TFTP_DIR/pxelinux.cfg
cp /usr/lib/PXELINUX/pxelinux.0 $P3ASORC_PXE_TFTP_DIR/
cp /usr/lib/syslinux/modules/bios/ldlinux.c32 $P3ASORC_PXE_TFTP_DIR/
cp /usr/lib/syslinux/modules/bios/menu.c32 $P3ASORC_PXE_TFTP_DIR/
cp /usr/lib/syslinux/modules/bios/libutil.c32 $P3ASORC_PXE_TFTP_DIR/

# PASO 5: Descargar y preparar Thin Client (SliTaz)
if [ ! -f /tmp/slitaz.iso ]; then
    wget -O /tmp/slitaz.iso $P3ASORC_PXE_URL_ISO
fi

mkdir -p /tmp/iso_mount
mkdir -p $P3ASORC_PXE_TFTP_DIR/slitaz
mount -o loop /tmp/slitaz.iso /tmp/iso_mount

# SliTaz Rolling tiene multiples rootfs (rootfs1.gz, rootfs2.gz, etc)
# Los concatenamos todos en un solo archivo initrd.gz para cargar todo el entorno grafico
echo "Combinando sistemas de archivos de SliTaz..."
cat /tmp/iso_mount/boot/rootfs*.gz > $P3ASORC_PXE_TFTP_DIR/slitaz/initrd.gz
cp /tmp/iso_mount/boot/bzImage $P3ASORC_PXE_TFTP_DIR/slitaz/vmlinuz
umount /tmp/iso_mount

# PASO 6: Crear menu de arranque PXE
# Configuramos el arranque con los parametros especificos para SliTaz
cat > $P3ASORC_GRUPO_CONFIG_PXE <<EOF
DEFAULT menu.c32
PROMPT 0
TIMEOUT 50
MENU TITLE PXE Boot Menu - Debian 13 (Grafico)

LABEL slitaz
  MENU LABEL ^1) Thin Client Grafico (SliTaz Rolling)
  KERNEL slitaz/vmlinuz
  APPEND initrd=slitaz/initrd.gz rw root=/dev/null autologin
EOF

# PASO 7: Reiniciar servicios finales
systemctl restart isc-dhcp-server
systemctl restart tftpd-hpa

#-------------------------------------------------------
# Valida servicio
#-------------------------------------------------------
systemctl status isc-dhcp-server --no-pager
systemctl status tftpd-hpa --no-pager
netstat -tunelp | grep -E '67|69'
ls -R $P3ASORC_PXE_TFTP_DIR/slitaz

#-------------------------------------------------------
# Extraer logs, configs e historial
#-------------------------------------------------------
rm -rf $P3ASORC_MEMORIA
mkdir -p $P3ASORC_MEMORIA
mkdir -p $P3ASORC_CONFIG

# Copia de configuraciones
cp $P3ASORC_GRUPO_CONFIG_DHCP $P3ASORC_CONFIG/dhcpd.conf
cp $P3ASORC_GRUPO_CONFIG_TFTP $P3ASORC_CONFIG/tftpd-hpa
cp $P3ASORC_GRUPO_CONFIG_PXE $P3ASORC_CONFIG/default.pxe

# Extraccion de logs de estado
systemctl status --no-pager -l isc-dhcp-server > $P3ASORC_LOG
systemctl status --no-pager -l tftpd-hpa >> $P3ASORC_LOG

# Historial
history > $P3ASORC_HISTORIAL
chmod 777 -R $P3ASORC_MEMORIA

tree $P3ASORC_MEMORIA

#-------------------------------------------------------
# Comprobacion desde host
#-------------------------------------------------------
# Iniciar VM Cliente -> Menu PXE -> Seleccionar SliTaz.
# Pulsa <enter> 2 veces
# Deberias ver un escritorio grafico completo cargado en RAM.
# Ejecuta lxde-session si fuera necesario.
# Usuario: root password: root