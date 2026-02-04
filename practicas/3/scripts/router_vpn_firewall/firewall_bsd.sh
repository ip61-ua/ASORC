#!/bin/sh
su -

#-------------------------------------------------------
# Variables de entorno
#-------------------------------------------------------
P3ASORC_SERVICIO=router_vpn_firewall
P3ASORC_SISTEMA=unix

# NO TOCAR
P3ASORC_MEMORIA=/home/ivan/SUPERMEMORIA/$P3ASORC_SERVICIO
P3ASORC_CONFIG=$P3ASORC_MEMORIA/ficheros_configuracion
P3ASORC_LOG=$P3ASORC_MEMORIA/$P3ASORC_SISTEMA.log
P3ASORC_HISTORIAL=$P3ASORC_MEMORIA/history$P3ASORC_SISTEMA.txt
P3ASORC_BSD_RC=/etc/rc.conf

# -
P3ASORC_FIREWALL_CONFIG=/etc/pf.conf

#-------------------------------------------------------
# Servicio
#-------------------------------------------------------

# PASO 0. Crear configuración
# Permitir solo páginas y SSH.
cat << EOF > $P3ASORC_FIREWALL_CONFIG
block all
pass out all keep state
pass in proto tcp from any to any port 80
EOF

# PASO A: Activar
sysrc pf_enable="YES"
sysrc pf_rules="$P3ASORC_FIREWALL_CONFIG"
sysrc pflog_enable="YES"
service pf start
pfctl -sr

# PASO B: Destactivar
service pf stop
sysrc pf_enable="NO"
sysrc pf_rules="$P3ASORC_FIREWALL_CONFIG"
sysrc pflog_enable="NO"


#-------------------------------------------------------
# Valida servicio
#-------------------------------------------------------
service apache24 status
pfctl -sr

#-------------------------------------------------------
# Extraer logs, configs e historial
#-------------------------------------------------------
rm -rf $P3ASORC_MEMORIA
mkdir -p $P3ASORC_MEMORIA
mkdir -p $P3ASORC_CONFIG

cp $P3ASORC_FIREWALL_CONFIG $P3ASORC_CONFIG/
cp $P3ASORC_BSD_RC $P3ASORC_CONFIG/rc.conf

touch $P3ASORC_LOG
pfctl -sr > $P3ASORC_LOG
history > $P3ASORC_HISTORIAL
chmod 777 -R $P3ASORC_MEMORIA

tree $P3ASORC_MEMORIA

#-------------------------------------------------------
# Comprobación desde host
#-------------------------------------------------------
curl -I http://192.168.25.11/SOGo
ping -c 1 192.168.25.11
