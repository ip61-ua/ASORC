#!/bin/sh
su -

#-------------------------------------------------------
# Variables de entorno
#-------------------------------------------------------
P3ASORC_SERVICIO=nagios
P3ASORC_SISTEMA=unix

# NO TOCAR
P3ASORC_MEMORIA=/home/ivan/SUPERMEMORIA/$P3ASORC_SERVICIO
P3ASORC_CONFIG=$P3ASORC_MEMORIA/ficheros_configuracion
P3ASORC_LOG=$P3ASORC_MEMORIA/$P3ASORC_SISTEMA.log
P3ASORC_HISTORIAL=$P3ASORC_MEMORIA/history$P3ASORC_SISTEMA.txt
P3ASORC_BSD_RC=/etc/rc.conf

# ---
P3ASORC_NAGIOS_USER=ivan
P3ASORC_NAGIOS_PASS=1
P3ASORC_NAGIOS_OBJECTS_DIR=/usr/local/etc/nagios/objects
P3ASORC_NAGIOS_CONFIG=/usr/local/etc/nagios/nagios.cfg
P3ASORC_NAGIOS_MAIN_LOG=/var/spool/nagios/nagios.log
P3ASORC_NAGIOS_HOST_CONFIG=/usr/local/etc/nagios/objects/localhost.cfg
P3ASORC_NAGIOS_APACHE_CONF=/usr/local/etc/apache24/httpd.conf
P3ASORC_NAGIOS_APACHE_CONF_DIR=/usr/local/etc/apache24
P3ASORC_NAGIOS_APACHE_HTPASSWD=/usr/local/etc/nagios/htpasswd.users
P3ASORC_NAGIOS_APACHE_NAGIOS_CONF=/usr/local/etc/apache24/Includes/nagios.conf
P3ASORC_NAGIOS_CFG_SAMPLE_NAME="nagios.cfg-sample"
P3ASORC_NAGIOS_HOST_CFG_SAMPLE_NAME="localhost.cfg-sample"
P3ASORC_NAGIOS_SPOOL=/var/spool/nagios

#-------------------------------------------------------
# Servicio
#-------------------------------------------------------
# PASO 0: Limpieza
service nagios stop
service apache24 stop
rm -rf $P3ASORC_NAGIOS_CONFIG $P3ASORC_NAGIOS_MAIN_LOG $P3ASORC_NAGIOS_APACHE_HTPASSWD
pkg delete -y nagios
# Ojito que quizás no interese borrar
pkg delete apache php

# PASO 1: Instalar Nagios, plugins y Servidor Web (Apache)
# Instalamos los componentes principales
pkg install -y nagios nagios-plugins apache24 php83-extensions wget autoconf automake gettext gcc openssl net-snmp p5-Net-SNMP-Util php83-zlib php83-ctype php83-session php83-simplexml

# Archivos de objetos esenciales
cp /usr/local/etc/nagios/$P3ASORC_NAGIOS_CFG_SAMPLE_NAME $P3ASORC_NAGIOS_CONFIG
cp /usr/local/etc/nagios/$P3ASORC_NAGIOS_CGI_SAMPLE_NAME $P3ASORC_NAGIOS_CGI_CONFIG
cp /usr/local/etc/nagios/resource.cfg-sample /usr/local/etc/nagios/resource.cfg
cp $P3ASORC_NAGIOS_OBJECTS_DIR/commands.cfg-sample $P3ASORC_NAGIOS_OBJECTS_DIR/commands.cfg
cp $P3ASORC_NAGIOS_OBJECTS_DIR/contacts.cfg-sample $P3ASORC_NAGIOS_OBJECTS_DIR/contacts.cfg
cp $P3ASORC_NAGIOS_OBJECTS_DIR/timeperiods.cfg-sample $P3ASORC_NAGIOS_OBJECTS_DIR/timeperiods.cfg
cp $P3ASORC_NAGIOS_OBJECTS_DIR/templates.cfg-sample $P3ASORC_NAGIOS_OBJECTS_DIR/templates.cfg
cp $P3ASORC_NAGIOS_OBJECTS_DIR/$P3ASORC_NAGIOS_HOST_CFG_SAMPLE_NAME $P3ASORC_NAGIOS_HOST_CONFIG

# PASO 2: Configurar apache y usuarios
sysrc apache24_enable="YES"
mkdir -p $(dirname $P3ASORC_NAGIOS_APACHE_HTPASSWD)
htpasswd -cb $P3ASORC_NAGIOS_APACHE_HTPASSWD $P3ASORC_NAGIOS_USER $P3ASORC_NAGIOS_PASS

# Configuración PHP
cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
sed -i '' 's/DirectoryIndex index.html/DirectoryIndex index.php index.html index.htm/g' $P3ASORC_NAGIOS_APACHE_CONF

# Carga forzada de módulos (CGI y PHP)
cat << EOF >> $P3ASORC_NAGIOS_APACHE_CONF

# --- AGREGADO POR SCRIPT NAGIOS ---
LoadModule cgid_module libexec/apache24/mod_cgid.so
LoadModule cgi_module libexec/apache24/mod_cgi.so

<FilesMatch "\.php$">
    SetHandler application/x-httpd-php
</FilesMatch>
<FilesMatch "\.phps$">
    SetHandler application/x-httpd-php-source
</FilesMatch>
# ----------------------------------
EOF

# Configuración VirtualHost de Nagios
mkdir -p $(dirname $P3ASORC_NAGIOS_APACHE_NAGIOS_CONF)
cat << EOF > $P3ASORC_NAGIOS_APACHE_NAGIOS_CONF
ScriptAlias /nagios/cgi-bin "/usr/local/www/nagios/cgi-bin"

<Directory "/usr/local/www/nagios/cgi-bin">
    AllowOverride None
    Options ExecCGI
    AddHandler cgi-script .cgis
    AuthName "Nagios Access"
    AuthType Basic
    AuthUserFile $P3ASORC_NAGIOS_APACHE_HTPASSWD
    Require valid-user
</Directory>


Alias /nagios "/usr/local/www/nagios"

<Directory "/usr/local/www/nagios">
    Options None

    AuthName "Nagios Access"
    AuthType Basic
    AuthUserFile $P3ASORC_NAGIOS_APACHE_HTPASSWD
    Require valid-user
</Directory>
EOF

# PASO 3: Configurar Nagios Daemon y permisos de usuario
echo "--- CONFIGURACION NAGIOS Y PERMISOS ---"
sysrc nagios_enable="YES"
sysrc nagios_user="www"

sed -i '' 's/nagios$/www/g' $P3ASORC_NAGIOS_CONFIG
sed -i '' 's/nagios$/www/g' $P3ASORC_NAGIOS_HOST_CONFIG
sed -i '' "s/nagios@localhost/$P3ASORC_NAGIOS_USER@bsd.asorc.org/g" $P3ASORC_NAGIOS_CONFIG

sed -i '' "s/nagiosadmin/$P3ASORC_NAGIOS_USER/g" $P3ASORC_NAGIOS_CGI_CONFIG
chmod 644 $P3ASORC_NAGIOS_CGI_CONFIG

# PASO 4: Otorgar permisos de sistema y comprobación
rm -f $P3ASORC_NAGIOS_SPOOL/nagios.log $P3ASORC_NAGIOS_SPOOL/status.sav
chown -R www:www $P3ASORC_NAGIOS_SPOOL
chmod -R 775 $P3ASORC_NAGIOS_SPOOL

# Permisos de ejecución CGI
chmod +x /usr/local/www/nagios/cgi-bin/*
chown root:www /usr/local/www/nagios/cgi-bin/*

# Verificación final
nagios -v $P3ASORC_NAGIOS_CONFIG

# Arranque
service apache24 start
service nagios start
service apache24 restart
service nagios restart

# FIX PARA PHP83
sed -i .bak 's/^nagios_user=www/nagios_user=nagios/' /usr/local/etc/nagios/nagios.cfg
sed -i .bak 's/^nagios_group=www/nagios_group=nagios/' /usr/local/etc/nagios/nagios.cfg
pw groupmod nagios -m www
chmod -R 775 /var/spool/nagios
chown -R nagios:nagios /var/spool/nagios
/usr/local/bin/nagios -v /usr/local/etc/nagios/nagios.cfg
service apache24 start
service nagios start
service apache24 restart
service nagios restart

#-------------------------------------------------------
# Valida servicio
#-------------------------------------------------------
service nagios status
service apache24 status
sockstat | grep -E 'nagios|httpd'

#-------------------------------------------------------
# Extraer logs, configs e historial
#-------------------------------------------------------
rm -rf $P3ASORC_MEMORIA
mkdir -p $P3ASORC_MEMORIA
mkdir -p $P3ASORC_CONFIG

cp $P3ASORC_NAGIOS_CONFIG $P3ASORC_CONFIG
cp $P3ASORC_NAGIOS_CGI_CONFIG $P3ASORC_CONFIG
cp $P3ASORC_NAGIOS_HOST_CONFIG $P3ASORC_CONFIG/localhost.cfg
cp $P3ASORC_NAGIOS_APACHE_CONF $P3ASORC_CONFIG/httpd.conf
cp /usr/local/etc/php.ini $P3ASORC_CONFIG/php.ini
cp $P3ASORC_APACHE_HTPASSWD $P3ASORC_CONFIG
cp $P3ASORC_NAGIOS_APACHE_NAGIOS_CONF $P3ASORC_CONFIG
cp $P3ASORC_BSD_RC $P3ASORC_CONFIG
cp $P3ASORC_NAGIOS_MAIN_LOG $P3ASORC_LOG

history > $P3ASORC_HISTORIAL
chmod 777 -R $P3ASORC_MEMORIA

tree $P3ASORC_MEMORIA

#-------------------------------------------------------
# Comprobación
#-------------------------------------------------------
firefox http://192.168.25.11/nagios/
firefox http://bsd.asorc.org/nagios/
