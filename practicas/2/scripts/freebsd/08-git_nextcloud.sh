#!/bin/bash

# ---- GIT ----
# Crea directorio
mkdir -p /var/srv/git/practica2.git

# Inicializa directorio
git init --bare /var/srv/git/practica2.git

# Otorgar permisos a usuarios
# Aquí lo suyo sería crear un usuario aparte y que solo tenga acceso a git
chown -R ivan:ivan /var/srv/git/

# ---- NEXTCLOUD ----
# Congurar apache2
nano /usr/local/etc/apache24/httpd.conf
# Descomentar 192 133 181 340
# Comentar 334
# L217 => ServerAdmin root@asorc.org
# L226 => ServerName www.bsd.asorc.org:80
# L264 => Options FollowSymLinks
# L271 => AllowOverride All
# L287 => DirectoryIndex index.html index.php index.cgi

nano /usr/local/etc/php-fpm.d/www.conf
# L45 => listen = /var/run/php-fpm.sock
# descomentar 57 58

nano /usr/local/etc/apache24/extra/httpd-ssl.conf
# Poner esto
#   <FilesMatch \.php$>
#         SetHandler "proxy:unix:/var/run/php-fpm.sock|fcgi://localhost/"
#     </FilesMatch>
# </VirtualHost>

# Habilitar php_fpm y apache
sysrc php_fpm_enable="YES"
sysrc apache24_enable="YES"
service php_fpm start
service apache24 reload

# Configuración mariadb
cat << 'EOF' > /usr/local/etc/mysql/conf.d/server.cnf
# Options specific to server applications, see
# https://mariadb.com/kb/en/configuring-mariadb-with-option-files/#server-option-groups

# Options specific to all server programs
[server]

# Options specific to MariaDB server programs
[server-mariadb]

#
# Options for specific server tools
#

[mysqld]
user                            = mysql
# port                          = 3306 # inherited from /usr/local/etc/mysql/my.cnf
socket                          = /var/run/mysql/mysql.sock # inherited from /usr/local/etc/mysql/my.cnf
bind-address                    = 127.0.0.1
basedir                         = /usr/local
# datadir                       = /var/db/mysql # --db_dir is set from rc.d
net_retry_count                 = 16384
log_error                       = /var/log/mysql/mysqld.err
character-set-server            = utf8mb4
collation-server                = utf8mb4_general_ci
# [mysqld] configuration for ZFS
# From https://www.percona.com/resources/technical-presentations/zfs-mysql-percona-technical-webinar
# Create separate datasets for data and logs, eg
# zroot/mysql      compression=on recordsize=128k atime=off
# zroot/mysql/data recordsize=16k
# zroot/mysql/logs
# datadir                       = /var/db/mysql/data
# innodb_log_group_home_dir     = /var/db/mysql/log
# audit_log_file                = /var/db/mysql/log/audit.log
# general_log_file              = /var/db/mysql/log/general.log
# log_bin                       = /var/db/mysql/log/mysql-bin
# relay_log                     = /var/db/mysql/log/relay-log
# slow_query_log_file           = /var/db/mysql/log/slow.log
# innodb_doublewrite            = 0
# innodb_flush_method           = O_DSYNC

# Options read by `mariadb_safe`
# Renamed from [mysqld_safe] starting with MariaDB 10.4.6.
[mariadb-safe]

# Options read my `mariabackup`
[mariabackup]

# Options read by `mysql_upgrade`
# Renamed from [mysql_upgrade] starting with MariaDB 10.4.6.
[mariadb-upgrade]

# Specific options read by the mariabackup SST method
[sst]

# Options read by `mysqlbinlog`
# Renamed from [mysqlbinlog] starting with MariaDB 10.4.6.
[mariadb-binlog]

# Options read by `mysqladmin`
# Renamed from [mysqladmin] starting with MariaDB 10.4.6.
[mariadb-admin]

EOF
sysrc mysql_enable="YES"
service mysql-server start
mysql_secure_installation
# n n ...el resto y

# Crea usuario para NextCloud
cat << 'EOF' | mysql
CREATE DATABASE IF NOT EXISTS nextcloud;
CREATE USER IF NOT EXISTS 'nextclouduser'@'localhost' IDENTIFIED BY 'passwd';
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextclouduser'@'localhost';
FLUSH PRIVILEGES;
exit
EOF

###########
# Borrado #
###########
service mysql-server stop
rm -rf /var/db/mysql/*
mysql_install_db --datadir=/var/db/mysql --user=mysql
service mysql-server start
###########

# Configuración NextCloud
cat << 'EOF' > /usr/local/etc/php-fpm.d/nextcloud.conf
[nextcloud]
user = www
group = www

listen.owner = www
listen.group = www
listen = /var/run/nextcloud.sock
listen.allowed_clients = 0.0.0.0

pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35

env[HOSTNAME] = $HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp

php_value[session.save_handler] = files
php_value[session.save_path]    = /usr/local/lib/php/sessions

php_value[max_execution_time] = 3600
php_value[memory_limit] = 1G
php_value[post_max_size] = 1G
php_value[upload_max_filesize] = 1G
php_value[max_input_time] = 3600
php_value[max_input_vars] = 2000
php_value[date.timezone] = Europe/Madrid

php_value[opcache.memory_consumption] = 128
php_value[opcache.interned_strings_buffer] = 32
php_value[opcache.max_accelerated_files] = 10000
php_value[opcache.revalidate_freq] = 1
php_value[opcache.save_comments] = 1
php_value[opcache.jit] = 1255
php_value[opcache.jit_buffer_size] = 128M
EOF

# Permisos
sysrc php_fpm_enable="YES"
mkdir /usr/local/lib/php/sessions
chown www:www /usr/local/lib/php/sessions
service php_fpm start
service php_fpm reload

# Descarga, descomprime NextCloud, luego otorga permisos
mkdir -p /var/www/
cd /var/www/
curl -o nextcloud.zip https://download.nextcloud.com/server/releases/latest.zip
unzip nextcloud.zip
chown -R www:www nextcloud
rm nextcloud.zip

# Ajustar página para la escucha de NextCloud.
cat << 'EOF' > /usr/local/etc/apache24/Includes/nextcloud.conf
<VirtualHost *:80>
  ServerName nextbsd.org
  DocumentRoot /var/www/nextcloud/
  
  ErrorLog /var/log/nextbsd.org-error.log
  CustomLog /var/log/nextbsd.org-access.log combined
  

  <Directory /var/www/nextcloud/>
     # Options +FollowSymlinks
     AllowOverride All
     Require all granted

     # SetEnv HOME /var/www/nextcloud
     # SetEnv HTTP_HOME /var/www/nextcloud

    <FilesMatch \.(php|phar)$>
        SetHandler "proxy:unix:/var/run/nextcloud.sock|fcgi://localhost"
    </FilesMatch>
  </Directory>
</VirtualHost>
EOF

# Declarar dominios fiables para NextCloud
mkdir -p /var/www/html/nextcloud/config
cat << 'EOF' > /var/www/html/nextcloud/config/config.php
  'debug' => true,
  'trusted_domains' =>
  array (
    0 => '192.168.25.10',
    1 => 'nextbsd.org',
  ),
EOF

# Aplica cambios
service apache24 restart
service redis enable
service redis start