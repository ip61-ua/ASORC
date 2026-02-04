#!/bin/sh
su -

#-------------------------------------------------------
# Variables de entorno
#-------------------------------------------------------
P3ASORC_SERVICIO=proxy
P3ASORC_SISTEMA=linux

# NO TOCAR
P3ASORC_MEMORIA=/home/ivan/SUPERMEMORIA/$P3ASORC_SERVICIO
P3ASORC_CONFIG=$P3ASORC_MEMORIA/ficheros_configuracion
P3ASORC_LOG=$P3ASORC_MEMORIA/$P3ASORC_SISTEMA.log
P3ASORC_HISTORIAL=$P3ASORC_MEMORIA/history$P3ASORC_SISTEMA.txt

# ---
P3ASORC_PROXY_CONFIG=/etc/squid/squid.conf
P3ASORC_PROXY_LOG1=/var/log/squid/access.log
P3ASORC_PROXY_LOG2=/var/log/squid/cache.log

#-------------------------------------------------------
# Servicio
#-------------------------------------------------------
# PASO 0: Limpieza
systemctl disable squid
systemctl stop squid
rm -rf $P3ASORC_PROXY_CONFIG $P3ASORC_PROXY_LOG2 $P3ASORC_PROXY_LOG1
apt remove -y squid

# PASO 1: Instalar y copiar configuración por defecto
apt install -y squid
cp $P3ASORC_PROXY_CONFIG $P3ASORC_PROXY_CONFIG.bak

# PASO 2: Configurar servicio
sysctl -w net.ipv4.ip_forward=1
cat << EOF > $P3ASORC_PROXY_CONFIG
http_port 3128
http_port 3129 intercept
cache_dir ufs /var/spool/squid 4096 16 256
coredump_dir /var/spool/squid
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
visible_hostname debian.asorc.org
dns_nameservers 1.1.1.1
debug_options ALL,1 11,2 33,2
EOF

# PASO 3: Activación y arranque el servicio
systemctl restart squid
systemctl enable squid

#-------------------------------------------------------
# Valida servicio
#-------------------------------------------------------
systemctl status squid
netstat -tunelp | grep -E 'squid'

#-------------------------------------------------------
# Extraer logs, configs e historial
#-------------------------------------------------------
rm -rf $P3ASORC_MEMORIA
mkdir -p $P3ASORC_MEMORIA
mkdir -p $P3ASORC_CONFIG

cp $P3ASORC_PROXY_CONFIG $P3ASORC_CONFIG
cp $P3ASORC_PROXY_LOG1 $P3ASORC_LOG
cat $P3ASORC_PROXY_LOG2 >> $P3ASORC_LOG

history > $P3ASORC_HISTORIAL
chmod 777 -R $P3ASORC_MEMORIA

tree $P3ASORC_MEMORIA

#-------------------------------------------------------
# Comprobación
#-------------------------------------------------------
HTTPS_PROXY=192.168.25.10:3128 HTTP_PROXY=192.168.25.10:3128 curl -I https://www.facebook.com/
HTTPS_PROXY=192.168.25.10:3128 HTTP_PROXY=192.168.25.10:3128 curl -I https://nitter.net/

