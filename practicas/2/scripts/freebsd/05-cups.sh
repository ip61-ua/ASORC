#!/bin/bash

# Configura cups servidor de impresión
sysrc cupsd_enable="YES"
sysrc devfs_system_ruleset="system"
sysrc avahi_daemon_enable="YES"
sysrc dbus_enable="YES"
service devfs start
service cupsd start
service devfs restart
service cupsd restart

# Añade al usuario 'ivan' al grupo 'cups' para permisos de admin de impresión
# LUEGO TOCA REINICIAR! (posiblemente)
pw groupmod cups -m ivan

# Sobrescribe el fichero de configuración principal de CUPS (/usr/local/etc/cups/cupsd.conf)
# - Logs verbosos
# - Atiende a cualquier interfaz en el puerto 631
# - Habilita el "Browsing" para anuncio de impresoras
# - Usar el protocolo 'dnssd' (Avahi/Bonjour) para anunciarse
# - Permite el acceso a la interfaz web desde la red local (@LOCAL)
# - Permite la administración desde la red local
# - Requiere un usuario del sistema (grupo @SYSTEM, que incluye a lpadmin)
mkdir -p /usr/local/etc/cups/
cat << 'EOF' > /usr/local/etc/cups/cupsd.conf
LogLevel debug
MaxLogSize 1024
# Listen localhost:631
Port 631
Listen /run/cups/cups.sock
Browsing Yes
BrowseLocalProtocols dnssd
DefaultAuthType Basic
WebInterface Yes

<Location />
  Order allow,deny
  Allow @LOCAL
</Location>

<Location /admin>
  AuthType Default
  Require user @SYSTEM
  Order allow,deny
  Allow @LOCAL
</Location>

<Location /admin/conf>
  AuthType Default
  Require user @SYSTEM
  Order allow,deny
</Location>

<Location /admin/log>
  AuthType Default
  Require user @SYSTEM
  Order allow,deny
</Location>

<Policy default>
  <Limit Create-Job Print-Job Print-URI Validate-Job>
    Order deny,allow
  </Limit>

  <Limit All>
    Order deny,allow
  </Limit>
</Policy>
EOF

# Sobrescribe el fichero de configuración del driver PDF
# - Establece la carpeta de salida para los PDFs generados
# - Define el grupo propietario de los ficheros generados
cat << 'EOF' > /usr/local/etc/cups/cups-pdf.conf
Out /var/spool/cups-pdf/IMPRESIONES
Grp cups
Grp daemon
AnonDirName /var/spool/cups-pdf/ANONYMOUS
Spool /var/spool/cups-pdf
Log /var/log/cups
LogType 5
GhostScript /usr/local/bin/gs
GSTmp /tmp
EOF

cat << 'EOF' > /etc/devfs.rules
[system=10]
add path 'unlpt' mode 0660 group cups
add path 'ulpt*' mode 0660 group cups
add path 'lpt*' mode 0660 group cups
add path 'usb/X.Y.Z' mode 0660 group cups
EOF

# Crea la carpeta de salida definida anteriormente y otorga permisos
mkdir -p /var/spool/cups-pdf/IMPRESIONES
chmod 777 /var/spool/cups-pdf/IMPRESIONES
chown cups:cups /var/spool/cups-pdf/IMPRESIONES
chmod 777 /var/spool/cups-pdf
chown cups:cups /var/spool/cups-pdf

# Reinicia el servicio CUPS para aplicar todos los cambios
service cupsd restart
service dbus start
service avahi-daemon start
service cupsd restart
service devfs start
service cupsd start
service devfs restart
service cupsd restart

# Añade la impresora PDF usando la línea de comandos (lpadmin)
lpadmin -p PDF_BSD_SUPER_IMPRESORA -E -v "cups-pdf:/" -P "/usr/local/share/cups/model/CUPS-PDF_noopt.ppd" -o printer-is-shared=true -m "driverless:pdf-file"

# Validar servicio CUPS
service cupsd status

# Salida de impresiones
ls /var/spool/cups-pdf/IMPRESIONES
ls /var/spool/cups-pdf/ANONYMOUS
