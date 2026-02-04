#!/bin/bash

# Instala mariadb
apt -y install mariadb-server

# Crea usuario para probar
cat << 'EOF' | mysql
CREATE DATABASE IF NOT EXISTS test_database;
CREATE USER IF NOT EXISTS 'item9'@'localhost' IDENTIFIED BY 'passwd';
GRANT ALL PRIVILEGES ON test_database.* TO 'item9'@'localhost';
FLUSH PRIVILEGES;
exit
EOF

cat << 'EOF' | mysql
CREATE DATABASE IF NOT EXISTS test_database;
CREATE TABLE test_database.test_table (id int, name varchar(50), address varchar(50), primary key (id));
INSERT INTO test_database.test_table(id, name, address) VALUES(1, "Ana Maria", "Pl. de las fuentes");
INSERT INTO test_database.test_table(id, name, address) VALUES(2, "Ivan", "Av. del pinar de la Horadada");
INSERT INTO test_database.test_table(id, name, address) VALUES(3, "Juan", "C/Larios");
INSERT INTO test_database.test_table(id, name, address) VALUES(4, "Teresa", "Glorieta Cinco vientos");
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
apt install -y php apache2

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

# Preparar sitio estático
mkdir -p /var/www/db
cd /var/www/
chown -R www-data:www-data db

# Crear front index.php
cat << 'EOF' > /var/www/db/index.php
<h1>SUS DATOS HAN SIDO FILTRADOS EN ESTA BASE DE DATOS</h1>
<h3>Qué no cunda el pánico aquí está súperbotón!</h3>
<button> Botón del pánico </button>
<br><hr><br>
<?php
$servername = "localhost";
$username = "item9";
$password = "passwd";
$dbname = "test_database";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
  die("Conexión fallida: " . $conn->connect_error);
}

$sql = "SELECT id, name, address FROM test_table";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
  // output data of each row
  while($row = $result->fetch_assoc()) {
    // ERROR 3 CORREGIDO: Faltaba un punto ('.') antes de $row["name"]
    echo "ID: " . $row["id"]. " - Name: " . $row["name"]. " - Address: " . $row["address"]. "<br>";
  }
} else {
  echo "0 resultados";
}
  $conn->close();
?>
EOF

# Ajustar página para la escucha de esta página
cat << 'EOF' > /etc/apache2/sites-available/db.conf
<VirtualHost *:80>
  ServerName dbdebian.org
  DocumentRoot /var/www/db/

  # Logging
  ErrorLog /var/log/apache2/dbdebian.org-error.log
  CustomLog /var/log/apache2/dbdebian.org-access.log combined

  <Directory /var/www/db/>
     # Options +FollowSymlinks
     AllowOverride All
     Require all granted

     # SetEnv HOME /var/www/db
     # SetEnv HTTP_HOME /var/www/db
  </Directory>
</VirtualHost>
EOF

# Habilita la página de prueba
a2ensite db.conf

# Deshabilita la página de bienvenida de PHP
a2dissite 000-default.conf

# Verifica la sintaxis de configuración de PHP
apachectl configtest

# Aplica cambios
systemctl reload apache2
rm -f /var/www/html/index.html
systemctl restart apache2
