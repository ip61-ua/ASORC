#!/bin/bash

# Instala: - cups (servidor de impresión)
#          - printer-driver-cups-pdf (el driver de impresora PDF)
#          - avahi-daemon (el servicio de descubrimiento Avahi)
#          - ghostscript (para evitar PDFs en blanco)
#          - cups-filters (filtros de CUPS)
apt install -y cups printer-driver-cups-pdf avahi-daemon ghostscript cups-filters

# Añade al usuario 'ivan' al grupo 'lpadmin' para permisos de admin de impresión
# LUEGO TOCA REINICIAR! (posiblemente)
usermod -a -G lpadmin ivan

# Sobrescribe el fichero de configuración principal de CUPS (/etc/cups/cupsd.conf)
# - Logs verbosos
# - Atiende a cualquier interfaz en el puerto 631
# - Habilita el "Browsing" para anuncio de impresoras
# - Usar el protocolo 'dnssd' (Avahi/Bonjour) para anunciarse
# - Permite el acceso a la interfaz web desde la red local (@LOCAL)
# - Permite la administración desde la red local
# - Requiere un usuario del sistema (grupo @SYSTEM, que incluye a lpadmin)
cat << 'EOF' > /etc/cups/cupsd.conf
LogLevel debug
MaxLogSize 0
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
cat << 'EOF' > /etc/cups/cups-pdf.conf
Out /var/spool/cups-pdf/IMPRESIONES

Grp lpadmin

DecodeHexStrings 1
EOF

# Crea la carpeta de salida definida anteriormente y otorga permisos
mkdir -p /var/spool/cups-pdf/IMPRESIONES
chmod 777 /var/spool/cups-pdf/IMPRESIONES
# Reinicia el servicio CUPS para aplicar todos los cambios
systemctl restart cups

# Añade la impresora PDF usando la línea de comandos (lpadmin)
lpadmin -p PDF_DEBIAN_SUPER_IMPRESORA -E -v "cups-pdf:/" \
-P "/usr/share/ppd/cups-pdf/CUPS-PDF_opt.ppd" \
-o printer-is-shared=true

# Validar servicio CUPS
systemctl status cups

# Salida de impresiones
ls /var/spool/cups-pdf/IMPRESIONES
ls /var/spool/cups-pdf/ANONYMOUS
