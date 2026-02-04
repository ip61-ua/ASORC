#!/bin/bash

# Crea usuario para Wordpress y grav
cat << 'EOF' | mysql
CREATE DATABASE IF NOT EXISTS grav_db;
CREATE USER IF NOT EXISTS 'grav_user'@'localhost' IDENTIFIED BY 'passwd_grav';
GRANT ALL PRIVILEGES ON grav_db.* TO 'grav_user'@'localhost';
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS wordpress_db;
CREATE USER IF NOT EXISTS 'wordpress_user'@'localhost' IDENTIFIED BY 'passwd_wp';
GRANT ALL PRIVILEGES ON wordpress_db.* TO 'wordpress_user'@'localhost';
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

# Preparar Wordpress
mkdir -p /var/www/wordpress
cd /var/www/
chown -R www:www wordpress
curl -o wordpress.zip https://wordpress.org/latest.zip
unzip wordpress.zip
rm wordpress.zip

# Preparar grav, mi password Qwertyuiop1234567890
rm -rf /var/www/grav
mkdir -p /var/www
cd /var/www/
wget https://github.com/getgrav/grav/releases/download/1.7.49.5/grav-admin-v1.7.49.5.zip
unzip grav-admin-v1.7.49.5.zip
rm grav-admin-v1.7.49.5.zip
mv grav-admin grav
chown -R www:www grav

# Ajustar página para la Wordpress
cat << 'EOF' > /usr/local/etc/apache24/Includes/wordpress.conf
<VirtualHost *:80>
  ServerName web1bsd.org
  DocumentRoot /var/www/wordpress/

  # Logging
  ErrorLog /var/log/web1bsd.org-error.log
  CustomLog /var/log/web1bsd.org-access.log combined

  <Directory /var/www/wordpress/>
     # Options +FollowSymlinks
     AllowOverride All
     Require all granted
     <FilesMatch \.(php|phar)$>
        SetHandler "proxy:unix:/var/run/php-fpm.sock|fcgi://localhost"
     </FilesMatch>
  </Directory>
</VirtualHost>
EOF

# Ajustar grav
cat << 'EOF' > /usr/local/etc/apache24/Includes/grav.conf
<VirtualHost *:80>
  ServerName web2bsd.org
  DocumentRoot /var/www/grav/

  # Logging
  ErrorLog /var/log/web2bsd.org-error.log
  CustomLog /var/log/web2bsd.org-access.log combined

  <Directory /var/www/grav/>
     # Options +FollowSymlinks
     AllowOverride All
     Require all granted
     <FilesMatch \.(php|phar)$>
        SetHandler "proxy:unix:/var/run/php-fpm.sock|fcgi://localhost"
     </FilesMatch>
  </Directory>
</VirtualHost>
EOF

# Reiniciar servicios y aplicar cambios
service apache24 restart
service redis restart
service php_fpm restart
