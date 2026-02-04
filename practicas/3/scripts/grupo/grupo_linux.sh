#!/bin/sh
su -

#-------------------------------------------------------
# Variables de entorno
#-------------------------------------------------------
P3ASORC_SERVICIO=grupo
P3ASORC_SISTEMA=linux

# NO TOCAR
P3ASORC_MEMORIA=/home/ivan/SUPERMEMORIA/$P3ASORC_SERVICIO
P3ASORC_CONFIG=$P3ASORC_MEMORIA/ficheros_configuracion
P3ASORC_LOG=$P3ASORC_MEMORIA/$P3ASORC_SISTEMA.log
P3ASORC_HISTORIAL=$P3ASORC_MEMORIA/history$P3ASORC_SISTEMA.txt

# ---
P3ASORC_GRUPO_CONFIG=/etc/citadel/citadel.rc
P3ASORC_GRUPO_LOG=/usr/local/citadel/data/log.0000000001

#-------------------------------------------------------
# Servicio (no backtrack)
#-------------------------------------------------------
# PASO 1: Instalar, compilar y configurar el servicio
curl https://easyinstall.citadel.org/install | bash
# <Enter>
# <Enter>
# <Enter>
# Y
# <Enter>
# 1
# <Enter>
# <Enter>
# <Enter> # Usará el puerto 504
# 0
# 8080
# 8443

#-------------------------------------------------------
# Valida servicio
#-------------------------------------------------------
systemctl status citadel
systemctl status webcit-http
systemctl status webcit-https
netstat -tunelp | grep -E 'webcit'

#-------------------------------------------------------
# Extraer logs, configs e historial
#-------------------------------------------------------
rm -rf $P3ASORC_MEMORIA
mkdir -p $P3ASORC_MEMORIA
mkdir -p $P3ASORC_CONFIG

cp $P3ASORC_GRUPO_CONFIG $P3ASORC_CONFIG
tr -cd '\11\12\15\40-\176' < $P3ASORC_GRUPO_LOG > $P3ASORC_LOG
systemctl status --no-pager -l citadel >> $P3ASORC_LOG
systemctl status --no-pager -l webcit-http >> $P3ASORC_LOG
systemctl status --no-pager -l webcit-https >> $P3ASORC_LOG

history > $P3ASORC_HISTORIAL
chmod 777 -R $P3ASORC_MEMORIA

tree $P3ASORC_MEMORIA

#-------------------------------------------------------
# Comprobación desde host
#-------------------------------------------------------
firefox 192.168.25.10:8080
# admin
# 1

# Desde guest
firefox localhost:8080
# usaurio1
# 1