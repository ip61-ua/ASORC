#!/bin/sh
su -

#-------------------------------------------------------
# Variables de entorno
#-------------------------------------------------------
P3ASORC_SERVICIO=pxe
P3ASORC_SISTEMA=unix

# NO TOCAR
P3ASORC_MEMORIA=/root/SUPERMEMORIA/$P3ASORC_SERVICIO
P3ASORC_CONFIG=$P3ASORC_MEMORIA/ficheros_configuracion
P3ASORC_LOG=$P3ASORC_MEMORIA/$P3ASORC_SISTEMA.log
P3ASORC_HISTORIAL=$P3ASORC_MEMORIA/history$P3ASORC_SISTEMA.txt

# --- VARIABLES ESPECIFICAS PXE ---
# En FreeBSD (VirtualBox Intel Pro/1000), el adaptador 2 suele ser em1
P3ASORC_PXE_IFACE=em1
P3ASORC_PXE_IP=192.168.25.11
P3ASORC_PXE_MASK=255.255.255.0
P3ASORC_PXE_RANGO_INI=192.168.25.101
P3ASORC_PXE_RANGO_FIN=192.168.25.150
P3ASORC_PXE_DNS=1.1.1.1
P3ASORC_PXE_TFTP_DIR=/var/tftpboot
# Usamos SliTaz para demo rapida (Entorno Grafico ligero).
P3ASORC_PXE_URL_ISO=http://mirror.slitaz.org/iso/rolling/slitaz-rolling.iso

# Rutas de configuracion FreeBSD
P3ASORC_GRUPO_CONFIG_DHCP=/usr/local/etc/dhcpd.conf
P3ASORC_GRUPO_CONFIG_PXE=$P3ASORC_PXE_TFTP_DIR/pxelinux.cfg/default
P3ASORC_INETD_CONF=/etc/inetd.conf

#-------------------------------------------------------
# Servicio
#-------------------------------------------------------

# PASO 1: Instalar paquetes y limpieza profunda
# Usamos pkg para instalar servidor DHCP y syslinux.
env ASSUME_ALWAYS_YES=yes pkg update -f
env ASSUME_ALWAYS_YES=yes pkg install isc-dhcp44-server syslinux wget

# Detener servicios y DESACTIVAR FIREWALLS (Causa principal de Timeouts)
service isc-dhcpd stop 2>/dev/null || true
service inetd stop 2>/dev/null || true
service pf stop 2>/dev/null || true
service ipfw stop 2>/dev/null || true
killall tftpd 2>/dev/null || true

# Limpieza de puertos
echo "Verificando puertos..."
sockstat -4 -l | grep -E ':67|:69' || echo "Puertos UDP 67/69 Libres"

# Crear directorio TFTP y asignar permisos
mkdir -p $P3ASORC_PXE_TFTP_DIR
chmod -R 777 $P3ASORC_PXE_TFTP_DIR

# PASO 2: Configurar servicios en rc.conf
# Habilitamos DHCPD e INETD
sysrc dhcpd_enable="YES"
sysrc dhcpd_ifaces="$P3ASORC_PXE_IFACE"
# Desactivamos firewalls permanentemente para la demo
sysrc pf_enable="NO"
sysrc firewall_enable="NO"
# Desactivamos tftpd standalone para evitar conflictos
sysrc tftpd_enable="NO"
# Activamos inetd con flags de escucha global
sysrc inetd_enable="YES"
sysrc inetd_flags="-wW -C 60"

# PASO 3: Configurar INETD para TFTP (Fix timeout)
# 1. Copia de seguridad
cp $P3ASORC_INETD_CONF ${P3ASORC_INETD_CONF}.bak
# 2. Borramos cualquier linea previa de tftp para evitar duplicados o errores
sed -i '' '/^tftp/d' $P3ASORC_INETD_CONF
sed -i '' '/^#tftp/d' $P3ASORC_INETD_CONF
# 3. Insertamos la linea limpia forzando udp4 y ruta correcta
# "udp4" asegura IPv4, "-l" logging, "-s" chroot seguro
echo "tftp dgram udp4 wait root /usr/libexec/tftpd tftpd -l -s $P3ASORC_PXE_TFTP_DIR" >> $P3ASORC_INETD_CONF

echo "Configuracion inetd regenerada correctamente."

# PASO 4: Configurar DHCPD
cat > $P3ASORC_GRUPO_CONFIG_DHCP <<EOF
option domain-name "pxelab.local";
option domain-name-servers $P3ASORC_PXE_DNS;
default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet 192.168.25.0 netmask $P3ASORC_PXE_MASK {
  range $P3ASORC_PXE_RANGO_INI $P3ASORC_PXE_RANGO_FIN;
  option routers 192.168.25.1;
  next-server $P3ASORC_PXE_IP;
  filename "pxelinux.0";
}
EOF

# PASO 5: Configurar ficheros Syslinux
SYSLINUX_PATH=/usr/local/share/syslinux/bios
mkdir -p $P3ASORC_PXE_TFTP_DIR/pxelinux.cfg

cp $SYSLINUX_PATH/core/pxelinux.0 $P3ASORC_PXE_TFTP_DIR/
cp $SYSLINUX_PATH/com32/elflink/ldlinux/ldlinux.c32 $P3ASORC_PXE_TFTP_DIR/
cp $SYSLINUX_PATH/com32/menu/menu.c32 $P3ASORC_PXE_TFTP_DIR/
cp $SYSLINUX_PATH/com32/libutil/libutil.c32 $P3ASORC_PXE_TFTP_DIR/

# PASO 6: Descargar y preparar Thin Client (ISO)
if [ ! -f /tmp/slitaz.iso ]; then
    echo "Descargando ISO..."
    wget -O /tmp/slitaz.iso $P3ASORC_PXE_URL_ISO
fi

mkdir -p /tmp/iso_mount
mkdir -p $P3ASORC_PXE_TFTP_DIR/slitaz

echo "Montando ISO via mdconfig..."
MD_UNIT=$(mdconfig -a -t vnode -f /tmp/slitaz.iso)
mount -t cd9660 /dev/$MD_UNIT /tmp/iso_mount

echo "Extrayendo kernel e initrd..."
cat /tmp/iso_mount/boot/rootfs*.gz > $P3ASORC_PXE_TFTP_DIR/slitaz/initrd.gz
cp /tmp/iso_mount/boot/bzImage $P3ASORC_PXE_TFTP_DIR/slitaz/vmlinuz

umount /tmp/iso_mount
mdconfig -d -u ${MD_UNIT#md}

# PASO 7: Crear menu de arranque PXE
cat > $P3ASORC_GRUPO_CONFIG_PXE <<EOF
DEFAULT menu.c32
PROMPT 0
TIMEOUT 50
MENU TITLE PXE Boot Menu - FreeBSD 14.3 (Grafico)

LABEL slitaz
  MENU LABEL ^1) Thin Client Grafico (SliTaz/XFCE Compliant)
  KERNEL slitaz/vmlinuz
  APPEND initrd=slitaz/initrd.gz rw root=/dev/null autologin
EOF

# PASO 8: Reiniciar servicios finales
# Reiniciamos inetd (TFTP) y dhcpd
service inetd restart
service isc-dhcpd restart

#-------------------------------------------------------
# Validación
#-------------------------------------------------------
echo "Estado de servicios:"
service isc-dhcpd status
service inetd status
echo "Escucha de puertos (Debe aparecer *:69):"
sockstat -4 -l | grep -E ':67|:69'
ls -R $P3ASORC_PXE_TFTP_DIR/slitaz

#-------------------------------------------------------
# Extracción logs
#-------------------------------------------------------
rm -rf $P3ASORC_MEMORIA
mkdir -p $P3ASORC_MEMORIA
mkdir -p $P3ASORC_CONFIG

# Copia de configuraciones
cp $P3ASORC_GRUPO_CONFIG_DHCP $P3ASORC_CONFIG/dhcpd.conf
grep tftp $P3ASORC_INETD_CONF > $P3ASORC_CONFIG/inetd_tftp_line
cp $P3ASORC_GRUPO_CONFIG_PXE $P3ASORC_CONFIG/default.pxe

# Logs (FreeBSD usa /var/log/messages)
tail -n 50 /var/log/messages | grep -E 'dhcpd|inetd|tftpd' > $P3ASORC_LOG

# Historial
history > $P3ASORC_HISTORIAL
chmod 777 -R $P3ASORC_MEMORIA

echo "Despliegue completado en $P3ASORC_MEMORIA"
tree $P3ASORC_MEMORIA || ls -R $P3ASORC_MEMORIA

#-------------------------------------------------------
# Comprobación
#-------------------------------------------------------
# Iniciar VM Cliente -> Menu PXE -> Seleccionar SliTaz.
# Pulsa <enter> 2 veces
# Deberias ver un escritorio grafico completo cargado en RAM.
# Ejecuta lxde-session si fuera necesario.
# Usuario: root password: root