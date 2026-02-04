#!/bin/bash

# Habilita PostgreSQL
sysrc postgresql_enable="YES"
/usr/local/etc/rc.d/postgresql initdb
service postgresql start

su - postgres
createuser ivan
createdb testdb -O ivan
exit
su ivan

# Insertar datos
cat << 'EOF' | psql testdb
CREATE TABLE IF NOT EXISTS test_table (linea int, destino text, hora text);
INSERT INTO test_table (linea, destino, hora) values (3,'El Campello', '07:19');
INSERT INTO test_table (linea, destino, hora) values (2,'Sant Vicent del Raspeig', '07:24');
INSERT INTO test_table (linea, destino, hora) values (4,'Platja de Sant Joan', '07:29');
INSERT INTO test_table (linea, destino, hora) values (1,'Benidorm', '09:34');
INSERT INTO test_table (linea, destino, hora) values (2,'Sant Vicent del Raspeig', '07:39');
INSERT INTO test_table (linea, destino, hora) values (3,'El Campello', '07:49');
INSERT INTO test_table (linea, destino, hora) values (2,'Sant Vicent del Raspeig', '07:54');
INSERT INTO test_table (linea, destino, hora) values (4,'Platja de Sant Joan', '07:59');
INSERT INTO test_table (linea, destino, hora) values (1,'Benidorm', '08:04');
exit;
EOF

# Preparar sitio estático
mkdir -p /var/www/db
cd /var/www/
chown -R www-data:www-data db

# Crear front index.php
cat << 'EOF' > /var/www/db/index.php
<h1>PRóXIMOS TRENES</h1>
<h3>Botón de auxilio</h3>
<button>S.O.S.</button>
<br><hr><br>
<?php
$conn_string = "host=localhost port=5432 dbname=testdb user=ivan";

$conn = pg_connect($conn_string);

if (!$conn) {
  die("Conexión fallida: " . pg_last_error());
}

$sql = "SELECT linea, destino, hora FROM test_table";
$result = pg_query($conn, $sql);

if (!$result) {
    echo "Error en la consulta: " . pg_last_error();
} else {
    echo "<table border='1' style='width:100%; border-collapse: collapse;'>";
    echo "<tr style='background-color:#f2f2f2;'>
            <th style='padding: 8px;'>Línea</th>
            <th style='padding: 8px;'>Destino</th>
            <th style='padding: 8px;'>Hora</th>
          </tr>";

    while ($row = pg_fetch_assoc($result)) {
        $linea = $row['linea'];
        $estilo_fila = "";

        switch ($linea) {
            case '1':
                $estilo_fila = "style='background-color: #FADBD8;'";
                break;
            case '2':
                $estilo_fila = "style='background-color: #D5F5E3;'";
                break;
            case '3':
                $estilo_fila = "style='background-color: #FCF3CF;'";
                break;
            case '4':
                $estilo_fila = "style='background-color: #FAD7E3;'";
                break;
            default:
                $estilo_fila = "";
                break;
        }
        echo "<tr " . $estilo_fila . ">";


        echo "<td style='padding: 8px;'>" . htmlspecialchars($row['linea']) . "</td>";
        echo "<td style='padding: 8px;'>" . htmlspecialchars($row['destino']) . "</td>";
        echo "<td style='padding: 8px;'>" . htmlspecialchars($row['hora']) . "</td>";
        echo "</tr>";
    }

    echo "</table>";
}

pg_close($conn);
?>
EOF

# Ajustar página para la escucha de esta página
cat << 'EOF' > /usr/local/etc/apache24/Includes/db.conf
<VirtualHost *:80>
  ServerName dbbsd.org
  DocumentRoot /var/www/db/

  # Logging
  ErrorLog /var/log/dbbsd.org-error.log
  CustomLog /var/log/dbbsd.org-access.log combined

  <Directory /var/www/db/>
     # Options +FollowSymlinks
     AllowOverride All
     Require all granted

     # SetEnv HOME /var/www/db
     # SetEnv HTTP_HOME /var/www/db
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