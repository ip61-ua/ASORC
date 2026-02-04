#!/bin/bash

# Crea un fichero de configuración para SSH
# - Establece el nivel de log a DEBUG (verboso)
# - El resto de parámetros son por defecto
echo "Port 22
ListenAddress 0.0.0.0
SyslogFacility AUTH
LogLevel DEBUG
AuthorizedKeysFile      .ssh/authorized_keys
Subsystem       sftp    /usr/libexec/sftp-server" > /etc/ssh/sshd_config

# Elimina claves anteriores
rm -rf /etc/ssh/ssh_host_ecdsa_key.pub /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_ed25519_key /etc/ssh/ssh_host_rsa_key.pub /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_ed25519_key.pub

# Reinicia el servicio SSH para aplicar la nueva configuración
service sshd restart
reboot