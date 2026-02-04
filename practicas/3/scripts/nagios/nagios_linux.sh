#!/bin/sh
su -

#-------------------------------------------------------
# Variables de entorno
#-------------------------------------------------------
P3ASORC_SERVICIO=nagios
P3ASORC_SISTEMA=linux

# NO TOCAR
P3ASORC_MEMORIA=/home/ivan/SUPERMEMORIA/$P3ASORC_SERVICIO
P3ASORC_CONFIG=$P3ASORC_MEMORIA/ficheros_configuracion
P3ASORC_LOG=$P3ASORC_MEMORIA/$P3ASORC_SISTEMA.log
P3ASORC_HISTORIAL=$P3ASORC_MEMORIA/history$P3ASORC_SISTEMA.txt

# ---
P3ASORC_NAGIOS_USER=ivan
P3ASORC_NAGIOS_PASS=1
P3ASORC_NAGIOS_DIR=/etc/nagios4
P3ASORC_NAGIOS_CONFIG=$P3ASORC_NAGIOS_DIR/nagios.cfg
P3ASORC_NAGIOS_CGI_CONFIG=$P3ASORC_NAGIOS_DIR/cgi.cfg
P3ASORC_NAGIOS_HTPASSWD=$P3ASORC_NAGIOS_DIR/htpasswd.users
P3ASORC_NAGIOS_MAIN_LOG=/var/log/nagios4/nagios.log

#-------------------------------------------------------
# Servicio
#-------------------------------------------------------
# PASO 0: Limpieza
systemctl disable nagios4
rm -rf /etc/nagios4 /var/log/nagios4
apt remove -y nagios4 nagios-plugins-basic nagios-nrpe-plugin

# PASO 1: Instalar paquetes
apt install -y nagios4 nagios-plugins-basic nagios-plugins-contrib nagios-nrpe-plugin apache2 libapache2-mod-php unzip curl

# PASO 2: Autenticación apache
a2enmod cgi rewrite
htpasswd -c -b $P3ASORC_NAGIOS_HTPASSWD $P3ASORC_NAGIOS_USER $P3ASORC_NAGIOS_PASS
chown root:www-data $P3ASORC_NAGIOS_HTPASSWD
chmod 640 $P3ASORC_NAGIOS_HTPASSWD

# PASO 3: Configurar Nagios
sed -i "s/nagios@localhost/$P3ASORC_NAGIOS_USER@debian.asorc.org/g" $P3ASORC_NAGIOS_CONFIG
sed -i "s/nagiosadmin/$P3ASORC_NAGIOS_USER/g" $P3ASORC_NAGIOS_CGI_CONFIG

# PASO 4: Puesta en marcha del servicio
# Verificación de sintaxis
nagios4 -v $P3ASORC_NAGIOS_CONFIG
# Reiniciar servicios
systemctl restart apache2
systemctl restart nagios4
systemctl enable nagios4 apache2

#-------------------------------------------------------
# Valida servicio
#-------------------------------------------------------
systemctl status nagios4 --no-pager
systemctl status apache2 --no-pager
netstat -tunelp | grep -E 'nagios'
ss -tunelp | grep apache2

#-------------------------------------------------------
# Extraer logs, configs e historial
#-------------------------------------------------------
rm -rf $P3ASORC_MEMORIA
mkdir -p $P3ASORC_MEMORIA
mkdir -p $P3ASORC_CONFIG

cp $P3ASORC_NAGIOS_CONFIG $P3ASORC_CONFIG/
cp $P3ASORC_NAGIOS_CGI_CONFIG $P3ASORC_CONFIG/
cp /etc/apache2/conf-enabled/nagios4-cgi.conf $P3ASORC_CONFIG/apache_nagios.conf
cp $P3ASORC_NAGIOS_HTPASSWD $P3ASORC_CONFIG/
cp $P3ASORC_NAGIOS_MAIN_LOG $P3ASORC_LOG

history > $P3ASORC_HISTORIAL
chmod 777 -R $P3ASORC_MEMORIA

tree $P3ASORC_MEMORIA

#-------------------------------------------------------
# Comprobación
#-------------------------------------------------------
firefox http://192.168.25.10/nagios4
firefox http://debian.debian.asorc.org/nagios4
