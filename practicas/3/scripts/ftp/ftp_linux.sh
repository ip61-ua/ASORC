#!/bin/sh
su -

#-------------------------------------------------------
# Variables de entorno
#-------------------------------------------------------
P3ASORC_SERVICIO=ftp
P3ASORC_SISTEMA=linux

# NO TOCAR
P3ASORC_MEMORIA=/home/ivan/SUPERMEMORIA/$P3ASORC_SERVICIO
P3ASORC_CONFIG=$P3ASORC_MEMORIA/ficheros_configuracion
P3ASORC_LOG=$P3ASORC_MEMORIA/$P3ASORC_SISTEMA.log
P3ASORC_HISTORIAL=$P3ASORC_MEMORIA/history$P3ASORC_SISTEMA.txt

# ---
P3ASORC_FTP_HOME=/var/practica2/home
P3ASORC_FTP_USER1=usuario_jaula
P3ASORC_FTP_USER2=usuario_libre

P3ASORC_FTP_CONFIG_1=/etc/vsftpd.conf
P3ASORC_FTP_CONFIG_2=/etc/vsftpd.chroot_list
P3ASORC_FTP_LOG=/var/log/vsftpd.log

#-------------------------------------------------------
# Servicio
#-------------------------------------------------------
# PASO 1: Usuarios
# Borrar logs anteriores
rm -rf $P3ASORC_FTP_LOG

# Borrar si existen de antes
userdel $P3ASORC_FTP_USER1
userdel $P3ASORC_FTP_USER2
rm -rf $P3ASORC_FTP_HOME

# Crearlos
mkdir -p $P3ASORC_FTP_HOME
useradd -m -d $P3ASORC_FTP_HOME/$P3ASORC_FTP_USER1 -s /bin/bash $P3ASORC_FTP_USER1
echo -e '1\n1\n' | passwd $P3ASORC_FTP_USER1
useradd -m -d $P3ASORC_FTP_HOME/$P3ASORC_FTP_USER2 -s /bin/bash $P3ASORC_FTP_USER2
echo -e '1\n1\n' | passwd $P3ASORC_FTP_USER2

# PASO 2: Instalar paquetes
apt remove -y vsftpd
apt install -y vsftpd

# PASO 3: Configurar
# Enjaula a todos
cat << EOF > /etc/vsftpd.conf
xferlog_enable=YES
xferlog_file=$P3ASORC_FTP_LOG
log_ftp_protocol=YES
listen=YES
listen_ipv6=NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
chroot_list_enable=YES
chroot_list_file=$P3ASORC_FTP_CONFIG_2
allow_writeable_chroot=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
ssl_enable=NO
EOF

# Menos al libre
echo "$P3ASORC_FTP_USER2" > $P3ASORC_FTP_CONFIG_2

# PASO 4: Aplica cambios
systemctl restart vsftpd

#-------------------------------------------------------
# Valida servicio
#-------------------------------------------------------
systemctl status vsftpd
netstat -tunelp | grep -E 'ftp'

#-------------------------------------------------------
# Extraer logs, configs e historial
#-------------------------------------------------------
rm -rf $P3ASORC_MEMORIA
mkdir -p $P3ASORC_MEMORIA
mkdir -p $P3ASORC_CONFIG

cp $P3ASORC_FTP_CONFIG_1 $P3ASORC_CONFIG
cp $P3ASORC_FTP_CONFIG_2 $P3ASORC_CONFIG
cp $P3ASORC_FTP_LOG $P3ASORC_LOG
journalctl -u vsftpd --no-pager >> $P3ASORC_LOG

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

lftp -u usuario_jaula,1 192.168.25.10
lftp -u usuario_libre,1 192.168.25.10
