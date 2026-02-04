#!/bin/bash

# ---- GIT ----
# Instala git
apt -y install git

# Crea directorio
mkdir -p /srv/git/practica.git

# Inicializa directorio
git init --bare /srv/git/practica.git

# Otorgar permisos a usuarios
# Aquí lo suyo sería crear un usuario aparte y que solo tenga acceso a git
chown -R ivan:ivan /srv/git/

# ---- NEXTCLOUD ----
# Instala mariadb
apt -y install mariadb-server

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
systemctl stop mariadb
rm -rf /var/lib/mysql/*
mysql_install_db --datadir=/var/lib/mysql --user=mysql
systemctl start mariadb
###########

# Instala el todo lo que ponga php
apt install -y php php-cli php-common php-curl php-gd php-mysql php-xml php-json php-intl php-pear php-imagick php-dev php-mbstring php-zip php-soap php-bz2 php-bcmath php-gmp php-apcu curl unzip

# Configura el PHP de apache
cat << 'EOF' > /etc/php/8.4/apache2/php.init
[PHP]
engine = On
error_log = /dev/stderr
short_open_tag = Off
precision = 14
output_buffering = 4096
zlib.output_compression = Off
implicit_flush = Off
unserialize_callback_func =
serialize_precision = -1
disable_functions =
disable_classes =
expose_php = On
max_execution_time = 30
max_input_time = 60
memory_limit = 128M
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = On
display_startup_errors = Off
log_errors = On
log_errors_max_len = 1024
ignore_repeated_errors = Off
ignore_repeated_source = Off
report_memleaks = On
html_errors = On
variables_order = "GPCS"
request_order = "GP"
register_argc_argv = Off
auto_globals_jit = On
post_max_size = 8M
auto_prepend_file =
auto_append_file =
default_mimetype = "text/html"
default_charset = "UTF-8"
doc_root =
user_dir =
enable_dl = Off
file_uploads = On
upload_max_filesize = 2M
max_file_uploads = 20
allow_url_fopen = On
allow_url_include = Off
default_socket_timeout = 60
[CLI Server]
cli_server.color = On
[Date]
date.timezone = Europe/Madrid
[filter]
[iconv]
[intl]
[sqlite3]
[Pcre]
[Pdo]
[Pdo_mysql]
pdo_mysql.default_socket=
[Phar]
[mail function]
SMTP = localhost
smtp_port = 25
[SQL]
sql.safe_mode = Off
[ODBC]
odbc.allow_persistent = On
odbc.check_persistent = On
odbc.max_persistent = -1
odbc.max_links = -1
odbc.defaultlrl = 4096
odbc.defaultbinmode = 1
[Interbase]
ibase.allow_persistent = 1
ibase.max_persistent = -1
ibase.max_links = -1
[MySQLi]
mysqli.max_persistent = -1
mysqli.allow_persistent = On
mysqli.max_links = -1
mysqli.default_port = 3306
mysqli.default_socket =
mysqli.default_host =
mysqli.default_user =
mysqli.default_pw =
mysqli.reconnect = Off
[mysqlnd]
mysqlnd.collect_statistics = On
mysqlnd.collect_memory_statistics = Off
[OCI8]
[PostgreSQL]
pgsql.allow_persistent = On
pgsql.auto_reset_persistent = Off
pgsql.max_persistent = -1
pgsql.max_links = -1
pgsql.ignore_notice = 0
pgsql.log_notice = 0
[Sybase-CT]
sybct.allow_persistent = On
sybct.max_persistent = -1
sybct.max_links = -1
sybct.min_server_severity = 10
sybct.min_client_severity = 10
[bcmath]
bcmath.scale = 0
[browscap]
[Session]
session.save_handler = files
session.use_strict_mode = 0
session.use_cookies = 1
session.use_only_cookies = 1
session.name = PHPSESSID
session.auto_start = 0
session.cookie_lifetime = 0
session.cookie_path = /
session.serialize_handler = php
session.gc_probability = 1
session.gc_divisor = 1000
session.gc_maxlifetime = 1440
session.cache_limiter = nocache
session.cache_expire = 180
session.use_trans_sid = 0
[Assertion]
assert.active = On
assert.warning = On
assert.bail = Off
[COM]
[mbstring]
[gd]
[exif]
[Tidy]
tidy.clean_output = Off
[soap]
soap.wsdl_cache_enabled=1
soap.wsdl_cache_dir="/tmp"
soap.wsdl_cache_ttl=86400
soap.wsdl_cache_limit = 5
[sysvshm]
[ldap]
ldap.max_links = -1
[dba]
[opcache]
[curl]
[openssl]
[ffi]
EOF

# Descarga, descomprime NextCloud, luego otorga permisos
cd /var/www/
curl -o nextcloud.zip https://download.nextcloud.com/server/releases/latest.zip
unzip nextcloud.zip
chown -R www-data:www-data nextcloud
rm nextcloud.zip

# Ajustar página para la escucha de NextCloud,
cat << 'EOF' > /etc/apache2/sites-available/nextcloud.conf
<VirtualHost *:80>
  ServerName nextdebian.org
  DocumentRoot /var/www/nextcloud/

  # Logging
  ErrorLog /var/log/apache2/nextdebian.org-error.log
  CustomLog /var/log/apache2/nextdebian.org-access.log combined

  <Directory /var/www/nextcloud/>
     # Options +FollowSymlinks
     AllowOverride All
     Require all granted

     # SetEnv HOME /var/www/nextcloud
     # SetEnv HTTP_HOME /var/www/nextcloud
  </Directory>
</VirtualHost>
EOF

# Declarar dominios fiables para NextCloud
mkdir -p /var/www/html/nextcloud/config
cat << 'EOF' > /var/www/html/nextcloud/config/config.php
  'trusted_domains' =>
  array (
    0 => '192.168.25.10',
    1 => 'nextdebian.org',
  ),
EOF

# Habilita la página de NextCloud
a2ensite nextcloud.conf

# Cargar módulos de PHP
a2enmod rewrite headers env dir mime

# Deshabilita la página de bienvenida de PHP
a2dissite 000-default.conf

# Verifica la sintaxis de configuración de PHP
apachectl configtest

# Aplica cambios
systemctl reload apache2
rm -f /var/www/html/index.html
systemctl restart apache2

