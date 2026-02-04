#!/bin/sh
su -

#-------------------------------------------------------
# Variables de entorno
#-------------------------------------------------------
P3ASORC_SERVICIO=proxy
P3ASORC_SISTEMA=unix

# NO TOCAR
P3ASORC_MEMORIA=/home/ivan/SUPERMEMORIA/$P3ASORC_SERVICIO
P3ASORC_CONFIG=$P3ASORC_MEMORIA/ficheros_configuracion
P3ASORC_LOG=$P3ASORC_MEMORIA/$P3ASORC_SISTEMA.log
P3ASORC_HISTORIAL=$P3ASORC_MEMORIA/history$P3ASORC_SISTEMA.txt
P3ASORC_BSD_RC=/etc/rc.conf

# ---
P3ASORC_PROXY_CONFIG=/usr/local/etc/squid/squid.conf
P3ASORC_PROXY_LOG1=/var/log/squid/access.log
P3ASORC_PROXY_LOG2=/var/log/squid/cache.log

#-------------------------------------------------------
# Servicio
#-------------------------------------------------------
# PASO 0: Limpieza
service squid stop
sysrc -x squid_enable
rm -rf $P3ASORC_PROXY_CONFIG $P3ASORC_PROXY_LOG2 $P3ASORC_PROXY_LOG1
pkg delete -y squid

# PASO 1: Instalar y copiar configuración por defecto
pkg install -y squid
if [ -f $P3ASORC_PROXY_CONFIG ]; then
    cp $P3ASORC_PROXY_CONFIG $P3ASORC_PROXY_CONFIG.bak
fi

# PASO 2: Configurar servicio
sysctl net.inet.ip.forwarding=1
sysrc gateway_enable="YES"

# Crear archivo de configuración
cat << EOF > $P3ASORC_PROXY_CONFIG
http_port 3128
http_port 3129 intercept
cache_dir ufs /var/squid/cache 4096 16 256
coredump_dir /var/squid/cache
acl mi_red src 192.168.25.0/24
acl sitios_prohibidos dstdomain .facebook.com .instagram.com .twitter.com .laliga.com
acl contenido_prohibido urlpath_regex -i laliga adult porn gambling
acl SSL_ports port 443
acl Safe_ports port 80 21 443 70 210 1025-65535
acl CONNECT method CONNECT
http_access allow localhost manager
http_access deny manager
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access deny sitios_prohibidos
http_access deny contenido_prohibido
http_access allow mi_red
http_access allow localhost
http_access deny all
visible_hostname freebsd.asorc.org
dns_nameservers 1.1.1.1
debug_options ALL,1 11,2 33,2
EOF

# PASO 3: Activación y arranque el servicio
squid -z
sysrc squid_enable="YES"
service squid start

#-------------------------------------------------------
# Valida servicio
#-------------------------------------------------------
service squid status
sockstat | grep squid

#-------------------------------------------------------
# Extraer logs, configs e historial
#-------------------------------------------------------
rm -rf $P3ASORC_MEMORIA
mkdir -p $P3ASORC_MEMORIA
mkdir -p $P3ASORC_CONFIG

cp $P3ASORC_PROXY_CONFIG $P3ASORC_CONFIG
cat $P3ASORC_PROXY_LOG1 > $P3ASORC_LOG
cat $P3ASORC_PROXY_LOG2 >> $P3ASORC_LOG
cp $P3ASORC_BSD_RC $P3ASORC_CONFIG

history > $P3ASORC_HISTORIAL
chmod 777 -R $P3ASORC_MEMORIA

tree $P3ASORC_MEMORIA

#-------------------------------------------------------
# Comprobación desde host
#-------------------------------------------------------
HTTPS_PROXY=192.168.25.11:3128 HTTP_PROXY=192.168.25.11:3128 curl -I https://www.instagram.com/
HTTPS_PROXY=192.168.25.11:3128 HTTP_PROXY=192.168.25.11:3128 curl -I https://nitter.net/
