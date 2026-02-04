#!/bin/bash

# Instala el paquete del servidor OpenSSH
apt install -y openssh-server

# Crea un fichero de configuración personalizado para SSH
# - Establece el nivel de log a DEBUG (verboso)
# - El resto de parámetros son por defecto
echo "Port 22
#AddressFamily any
#ListenAddress 0.0.0.0
#ListenAddress ::
# Logging
SyslogFacility AUTH
LogLevel DEBUG

PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
# Allow client to pass locale and color environment variables
AcceptEnv LANG LC_* COLORTERM NO_COLOR
# override default of no subsystems
Subsystem	sftp	/usr/lib/openssh/sftp-server" > /etc/ssh/sshd_config.d/personalizar.conf
# Reinicia el servicio SSH para aplicar la nueva configuración
systemctl restart sshd
