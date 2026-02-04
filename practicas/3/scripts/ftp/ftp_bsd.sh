#!/bin/sh
su -

#-------------------------------------------------------
# Variables de entorno
#-------------------------------------------------------
P3ASORC_SERVICIO=ftp
P3ASORC_SISTEMA=unix

# NO TOCAR
P3ASORC_MEMORIA=/home/ivan/SUPERMEMORIA/$P3ASORC_SERVICIO
P3ASORC_CONFIG=$P3ASORC_MEMORIA/ficheros_configuracion
P3ASORC_LOG=$P3ASORC_MEMORIA/$P3ASORC_SISTEMA.log
P3ASORC_HISTORIAL=$P3ASORC_MEMORIA/history$P3ASORC_SISTEMA.txt
P3ASORC_BSD_RC=/etc/rc.conf

# ---
P3ASORC_FTP_HOME=/var/practica2/home
P3ASORC_FTP_USER1=usuario_jaula
P3ASORC_FTP_USER2=usuario_libre

P3ASORC_FTP_CONFIG_1=/usr/local/etc/proftpd.conf
P3ASORC_FTP_LOG=/var/log/proftpd.log
P3ASORC_FTP_LOG1=/var/log/proftpd.xtr.log
P3ASORC_FTP_LOG2=/var/log/proftpd.cmd.log

#-------------------------------------------------------
# Servicio
#-------------------------------------------------------
# PASO 1: Usuarios
# Borrar logs anteriores
rm -rf $P3ASORC_FTP_LOG
rm -rf $P3ASORC_FTP_LOG1
rm -rf $P3ASORC_FTP_LOG2

# Borrar si existen de antes
pw user del -n $P3ASORC_FTP_USER1 -r
pw user del -n $P3ASORC_FTP_USER2 -r
rm -rf $P3ASORC_FTP_HOME

# Crearlos
mkdir -p $P3ASORC_FTP_HOME
echo "1" | pw user add -n $P3ASORC_FTP_USER1 \
    -d $P3ASORC_FTP_HOME/$P3ASORC_FTP_USER1 \
    -s /usr/local/bin/bash \
    -m -h 0

echo "1" | pw user add -n $P3ASORC_FTP_USER2 \
    -d $P3ASORC_FTP_HOME/$P3ASORC_FTP_USER2 \
    -s /usr/local/bin/bash \
    -m -h 0

# PASO 2: Instalar paquetes
pkg remove -y proftpd
pkg install -y proftpd

# PASO 3: Configurar
# Enjaula a todos menos a uno
cat << EOF > $P3ASORC_FTP_CONFIG_1
RequireValidShell off
UseReverseDNS off
LogFormat detallado "%t [IP: %h] [User: %u] \"%r\" (Status: %s) - Bytes: %b"
SystemLog $P3ASORC_FTP_LOG
DebugLevel 9
TransferLog $P3ASORC_FTP_LOG1
ExtendedLog $P3ASORC_FTP_LOG2 ALL detallado
ServerName                      "Museo del Prado FTP"
ServerType                      standalone
DefaultServer                   on
ScoreboardFile          /var/run/proftpd/proftpd.scoreboard
Port                            21
UseIPv6                         on
Umask                           022
MaxInstances                    30
CommandBufferSize       512
User                            nobody
Group                           nogroup
DefaultRoot ~ !$P3ASORC_FTP_USER2
AllowOverwrite          on
<Limit SITE_CHMOD>
  DenyAll
</Limit>
EOF

# PASO 4: Aplica cambios
sysrc proftpd_enable="YES"
service proftpd restart

#-------------------------------------------------------
# Valida servicio
#-------------------------------------------------------
service proftpd status
sockstat | grep -E 'ftp'

#-------------------------------------------------------
# Extraer logs, configs e historial
#-------------------------------------------------------
rm -rf $P3ASORC_MEMORIA
mkdir -p $P3ASORC_MEMORIA
mkdir -p $P3ASORC_CONFIG

cp $P3ASORC_FTP_CONFIG_1 $P3ASORC_CONFIG
cp $P3ASORC_FTP_LOG $P3ASORC_LOG
cat $P3ASORC_FTP_LOG1 >> $P3ASORC_LOG
cat $P3ASORC_FTP_LOG2 >> $P3ASORC_LOG
cp $P3ASORC_BSD_RC $P3ASORC_CONFIG

history > $P3ASORC_HISTORIAL
chmod 777 -R $P3ASORC_MEMORIA

tree $P3ASORC_MEMORIA

#-------------------------------------------------------
# Comprobación desde host
#-------------------------------------------------------
sudo dnf install -y lftp

cat << EOF
rm -f hola.txt
ls
put hola.txt
ls
pwd
cd ..
pwd
quit
EOF

lftp -u usuario_jaula,1 192.168.25.11
lftp -u usuario_libre,1 192.168.25.11
