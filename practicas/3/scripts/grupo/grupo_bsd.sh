#!/bin/sh
su -

#-------------------------------------------------------
# Variables de entorno
#-------------------------------------------------------
P3ASORC_SERVICIO=grupo
P3ASORC_SISTEMA=unix

# NO TOCAR
P3ASORC_MEMORIA=/home/ivan/SUPERMEMORIA/$P3ASORC_SERVICIO
P3ASORC_CONFIG=$P3ASORC_MEMORIA/ficheros_configuracion
P3ASORC_LOG=$P3ASORC_MEMORIA/$P3ASORC_SISTEMA.log
P3ASORC_HISTORIAL=$P3ASORC_MEMORIA/history$P3ASORC_SISTEMA.txt
P3ASORC_BSD_RC=/etc/rc.conf

# ---- Intento cuarto #4
P3ASORC_GRUPO_CONFIG=/usr/local/etc/apache24/Includes/sogo.conf
P3ASORC_GRUPO_CONFIG1=/usr/local/etc/sogo/sogo.conf
P3ASORC_GRUPO_FDIR=/usr/local/GNUstep/Local/Library/SOGo/WebServerResources
P3ASORC_GRUPO_INTERPHONE_NUMBERLESS_INTERFACES_ATTENDERS_AND_LISTENERS=127.0.0.1:20000
P3ASORC_GRUPO_DB=sogod
P3ASORC_GRUPO_DB_USER=sogo
P3ASORC_GRUPO_DB_PASS=1

#-------------------------------------------------------
# Servicio (no backtrack) Intento #1 (Alternativa)
#-------------------------------------------------------
# PASO 1: Instalar paquete
pkg install -y moregroupware apache24 mod_php82 mariadb106-server

# PASO 2: Configuración de BD
sysrc mysql_enable="YES"
service mysql-server start
sleep 5

mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS moregroupware;
CREATE USER IF NOT EXISTS 'moregw_user'@'localhost' IDENTIFIED BY '1';
GRANT ALL PRIVILEGES ON moregroupware.* TO 'moregw_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# PASO 3: Configuración Web (Apache)...
cat << EOF > $P3ASORC_GRUPO_APACHECONF
Alias /phpgroupware /usr/local/www/phpgroupware/

<Directory /usr/local/www/phpgroupware/>
   Options Indexes FollowSymLinks MultiViews
   AllowOverride None
   Require all granted
   DirectoryIndex index.php login.php
</Directory>

<Directory /usr/local/www/phpgroupware/setup/>
   Options Indexes FollowSymLinks MultiViews
   AllowOverride None
   Require all granted
   DirectoryIndex index.php
</Directory>
EOF

chown -R www:www $P3ASORC_GRUPO_PHPGWDIR
sysrc apache24_enable="YES"
service apache24 restart
service apache24 status
service mysql-server status

#-------------------------------------------------------
# Servicio (no backtrack) Intento #2 (La matrioska)
#-------------------------------------------------------

# Este Intento consistía en:
# 1. Instalar VirtualBox
# 2. Compartir la carpeta de la máquina virtual de mi  debian (donde estaba el servicio)
# 3. La máquina funciona y arranca (ES COMO UNA MATRIOSKA, una VM dentro de otra VM)
# 4. El disco de debian, por haber osado utilizar las shapshots, pasaba a ser dinámico, y sus contenidos no eran actuales.
# 5. Copiar el disco a un espacio donde hubiera memoria requería tiempo, costes de lectura y escritura de al menos el doble que lo normal, y espacio (evitndemente)
# 6. Además iba lenta la VM
# 7. Idea era usar un tipo de conexión que permitiera enmascarar bajo la misma que el ahora host freebsd.
# Demasiada mente galaxia utilizada, muy enadeble a fallos y la lentitud hicieron echarme para atrás

#-------------------------------------------------------
# Servicio (no backtrack) Intento #3 (Contenedores)
#-------------------------------------------------------
P3ASORC_GRUPO_DB_ROOT_PASS="1"
P3ASORC_GRUPO_DB_USER_PASS="1"
P3ASORC_GRUPO_NETWORK_NAME="egroupware-net"

# PASO 1: Instalar podman
pkg install -y podman

# PASO 2: Declarar montaje
mount -t fdescfs fdesc /dev/fd
nano /etc/fstab
# meter esto
# fdesc           /dev/fd         fdescfs rw      0       0

# PASO 3: Habilitación de servicio
service podman enable
sudo sysrc podman_enable="YES"

# PASO 4: Aplicar configuración por defecto
cp /usr/local/etc/containers/pf.conf.sample /etc/pf.conf
kldload pf
sysctl net.pf.filter_local=1

# REQUIERE PROCESO A MANO
nano /etc/sysctl.conf
# net.pf.filter_local=1
nano /etc/pf.conf
# nat-anchor "cni-rdr/*"
# v4egress_if = "em0"

# PASO 4: Habilitar e iniciar Linux
pkg install -y linux_base-c7
mkdir -p /compat/linux/proc
mkdir -p /compat/linux/sys
mkdir -p /compat/linux/dev
mount -t linprocfs linproc /compat/linux/proc
mount -t linsysfs linsys /compat/linux/sys
mount -t devfs devfs /compat/linux/dev
service pf start
sysrc linux_enable="YES"
service linux start

# PASO 5: Crear espacio para contenerización
truncate -s 4G /var/zfs_virtual.img
zpool create -f zroot /var/zfs_virtual.img
sysrc zfs_enable="YES"
service zfs start
zfs create -o mountpoint=/var/db/containers zroot/containers
# PASO 6: Habilitar docker hub
cat << EOF > /usr/local/etc/containers/registries.conf
# Configuración de registros para Podman en FreeBSD
# Formato TOML v2
# Lista de registros donde buscar cuando no se especifica el servidor
unqualified-search-registries = ["docker.io", "quay.io"]
# Configuración para Docker Hub
[[registry]]
location = "docker.io"
# Permitir conexiones HTTPS (seguro)
insecure = false
# Configuración para Quay.io
[[registry]]
location = "quay.io"
insecure = false
EOF
service podman start
# PASO 7: Crear red
podman network create $P3ASORC_GRUPO_NETWORK_NAME --subnet 10.5.0.0/24

# PASO 8: Correr imagen
podman pull --os linux docker.io/egroupware/egroupware:23.1
podman run -d \
--os linux \
--network $P3ASORC_GRUPO_NETWORK_NAME \
--name db-egroupware \
-e MARIADB_ROOT_PASSWORD=$P3ASORC_GRUPO_DB_ROOT_PASS \
-e MARIADB_USER=egroupware \
-e MARIADB_PASSWORD=$P3ASORC_GRUPO_DB_USER_PASS \
-e MARIADB_DATABASE=egroupware \
mariadb:lts

sleep 40
podman run -d \
--os linux \
-p 8080:80 \
--network $P3ASORC_GRUPO_NETWORK_NAME \
--name grupo \
-e EGW_DB_HOST=db-egroupware \
-e EGW_DB_ROOT_USER=root \
-e EGW_DB_ROOT_PW=$P3ASORC_GRUPO_DB_ROOT_PASS \
-e EGW_DB_NAME=egroupware \
-e EGW_DB_USER=egroupware \
-e EGW_DB_PASS=$P3ASORC_GRUPO_DB_USER_PASS \
docker.io/egroupware/egroupware:23.1

sysrc bhyve_enable="YES"
sysrc docker_enable="YES"
docker-machine create -d virtualbox default
docker run -p 80:8080 --name grupo egroupware/egroupware:23.1

#-------------------------------------------------------
# Servicio (no backtrack) Intento #4 (La que no vi)
#-------------------------------------------------------
pkg install -y sogo-mysql mod_php83 php83-extensions php83-pdo sope2 php83-pecl-memcached php83-pecl-memcache memcached
sysrc mysql_enable="YES"
sysrc apache24_enable="YES"
sysrc sogod_enable="YES"
sysrc memcached_enable="YES"

sed -i '' 's/#LoadModule proxy_module/LoadModule proxy_module/' /usr/local/etc/apache24/httpd.conf
sed -i '' 's/#LoadModule proxy_http_module/LoadModule proxy_http_module/' /usr/local/etc/apache24/httpd.conf
sed -i '' 's/#LoadModule headers_module/LoadModule headers_module/' /usr/local/etc/apache24/httpd.conf
sed -i '' 's/#LoadModule alias_module/LoadModule alias_module/' /usr/local/etc/apache24/httpd.conf

service memcached start
service mysql-server start
service apache24 start
service memcached restart
service apache24 restart
service mysql-server restart

# Ojito
cat /var/db/mysql/*.err | tail -n 20
rm -rf /var/db/mysql/*

mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS $P3ASORC_GRUPO_DB;
CREATE USER IF NOT EXISTS '$P3ASORC_GRUPO_DB_USER'@'127.0.0.1' IDENTIFIED BY '$P3ASORC_GRUPO_DB_PASS';
GRANT ALL PRIVILEGES ON $P3ASORC_GRUPO_DB.* TO '$P3ASORC_GRUPO_DB_USER'@'127.0.0.1';
FLUSH PRIVILEGES;

USE $P3ASORC_GRUPO_DB;
CREATE TABLE IF NOT EXISTS sogo_view (
   c_uid VARCHAR(20) PRIMARY KEY,
   c_name VARCHAR(20),
   c_password VARCHAR(32),
   c_cn VARCHAR(128),
   mail VARCHAR(128)
);
INSERT IGNORE INTO sogo_view VALUES ('admin', 'admin', MD5('1'), 'Administrador', 'admin@local.host');
INSERT IGNORE INTO sogo_view VALUES ('$P3ASORC_GRUPO_DB_USER', '$P3ASORC_GRUPO_DB_USER', MD5('$P3ASORC_GRUPO_DB_PASS'), '$P3ASORC_GRUPO_DB_USER', '$P3ASORC_GRUPO_DB_USER@bsd.asorc.org');
EOF

cat << EOF > $P3ASORC_GRUPO_CONFIG1
{
  SOGoProfileURL = "mysql://$P3ASORC_GRUPO_DB_USER:$P3ASORC_GRUPO_DB_PASS@127.0.0.1:3306/$P3ASORC_GRUPO_DB/sogo_user_profile";
  OCSFolderInfoURL = "mysql://$P3ASORC_GRUPO_DB_USER:$P3ASORC_GRUPO_DB_PASS@127.0.0.1:3306/$P3ASORC_GRUPO_DB/sogo_folder_info";
  OCSSessionsFolderURL = "mysql://$P3ASORC_GRUPO_DB_USER:$P3ASORC_GRUPO_DB_PASS@127.0.0.1:3306/$P3ASORC_GRUPO_DB/sogo_sessions_folder";

  SOGoPageTitle = SOGo;
  SOGoLanguage = "Spanish";
  SOGoTimeZone = "Europe/Madrid";

  WOPort = "$P3ASORC_GRUPO_INTERPHONE_NUMBERLESS_INTERFACES_ATTENDERS_AND_LISTENERS";
  WOLogFile = /var/log/sogo/sogo.log;

  SOGoUserSources = (
    {
      type = sql;
      id = directory;
      viewURL = "mysql://$P3ASORC_GRUPO_DB_USER:$P3ASORC_GRUPO_DB_PASS@127.0.0.1:3306/$P3ASORC_GRUPO_DB/sogo_view";
      canAuthenticate = YES;
      isAddressBook = YES;
      userPasswordAlgorithm = md5;
    }
  );
}
EOF

cat << EOF > $P3ASORC_GRUPO_CONFIG
Alias /SOGo.woa/WebServerResources/ $P3ASORC_GRUPO_FDIR/
Alias /SOGo/WebServerResources/ $P3ASORC_GRUPO_FDIR/

<Directory $P3ASORC_GRUPO_FDIR/>
    AllowOverride None
    Require all granted
</Directory>

ProxyRequests Off
SetEnv proxy-nokeepalive 1
ProxyPreserveHost On

ProxyPass /SOGo http://$P3ASORC_GRUPO_INTERPHONE_NUMBERLESS_INTERFACES_ATTENDERS_AND_LISTENERS/SOGo retry=0
ProxyPassReverse /SOGo http://$P3ASORC_GRUPO_INTERPHONE_NUMBERLESS_INTERFACES_ATTENDERS_AND_LISTENERS/SOGo
EOF

chmod -R 755 /usr/local/GNUstep/Local/Library/SOGo/WebServerResources/

service sogod restart
service apache24 restart

#-------------------------------------------------------
# Valida servicio
#-------------------------------------------------------
service apache24 status
service mysql-server status
service sogod status
sockstat -l | grep -E 'sogod'

#-------------------------------------------------------
# Extraer logs, configs e historial
#-------------------------------------------------------
rm -rf $P3ASORC_MEMORIA
mkdir -p $P3ASORC_MEMORIA
mkdir -p $P3ASORC_CONFIG

cp $P3ASORC_GRUPO_CONFIG1 $P3ASORC_CONFIG/sogo.conf
cp $P3ASORC_GRUPO_CONFIG $P3ASORC_CONFIG/apache_sogo.conf
cp /usr/local/etc/apache24/httpd.conf $P3ASORC_CONFIG/httpd.conf
cp $P3ASORC_BSD_RC $P3ASORC_CONFIG/rc.conf

touch $P3ASORC_LOG
echo "################### SOGO LOG ###################" >> $P3ASORC_LOG
cat /var/log/sogo/sogo.log >> $P3ASORC_LOG
echo -e "\n################### APACHE ERROR LOG ###################" >> $P3ASORC_LOG
cat /var/log/httpd-error.log >> $P3ASORC_LOG
echo -e "\n################### MYSQL ERROR LOG ###################" >> $P3ASORC_LOG
cat /var/db/mysql/*.err >> $P3ASORC_LOG

history > $P3ASORC_HISTORIAL
chmod 777 -R $P3ASORC_MEMORIA
tree $P3ASORC_MEMORIA

#-------------------------------------------------------
# Comprobación desde host
#-------------------------------------------------------
firefox http://192.168.25.11/SOGo
firefox http://bsd.asorc.org/SOGo
