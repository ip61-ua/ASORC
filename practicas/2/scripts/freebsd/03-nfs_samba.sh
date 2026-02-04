#!/bin/bash

# --- Configuración de NFS ---
# Añade parámetros a /etc/rc.conf
sysrc nfs_server_enable="YES"
sysrc nfsv4_server_enable="YES"
sysrc nfsuserd_enable="YES"
sysrc nfsuserd_flags=""

# Crea el directorio que se va a compartir y dar todos los permisos
mkdir -p /var/srv/nfs
chmod 777 /var/srv/nfs

# Sobrescribe /etc/exports para compartir /var/srv/nfs con la red 192.168.25.0/24
echo "V4: /var/srv -network 192.168.25.0 -mask 255.255.255.0
/var/srv/nfs -maproot=root" > /etc/exports
chmod 777 /etc/exports

# Aplica la configuración del fichero /etc/exports
# Añade parámetros a /etc/rc.conf
service nfsd start

# --- Configuración de SAMBA ---
sysrc samba_server_enable="YES"

# Crea el directorio para la compartición de Samba y permisos
mkdir -p /var/srv/samba
chmod 777 /var/srv/samba

# Sobrescribe el fichero de configuración de Samba (/etc/samba/smb.conf)
# - Hacer muy verboso
# - Define el recurso compartido en el apartado [publico]
# - path: Ruta al directorio físico
# - read only: Permite escritura
# - browsable: Hace que sea visible en la red
# - valid users: Dice que usuarios son válidos para este recurso (solo ivan)
echo -e '[global]
   log level = 5
   workgroup = WORKGROUP
   log file = /var/log/samba/log.%m
   max log size = 1000
   logging = file
   panic action = /usr/share/samba/panic-action %d
   server role = standalone server
   obey pam restrictions = yes
   unix password sync = yes
   passwd program = /usr/bin/passwd %u
   passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
   pam password change = yes
   map to guest = bad user
   usershare allow guests = yes
   unix charset = UTF-8
   server string = FreeBSD

[homes]
   comment = Home Directories
   browseable = no
   read only = yes
   create mask = 0700
   directory mask = 0700
   valid users = %S

[printers]
   comment = All Printers
   browseable = no
   path = /var/tmp
   printable = yes
   guest ok = no
   read only = yes
   create mask = 0700

[print$]
   comment = Printer Drivers
   path = /var/lib/samba/printers
   browseable = yes
   read only = yes
   guest ok = no

[publico]
   comment = Carpeta Publica de Samba
   path = /var/srv/samba
   read only = no
   browsable = yes
   force user = ivan
   force group = wheel' > /usr/local/etc/smb4.conf

echo '1
1
' | smbpasswd -a ivan

# Aplicar cambios
service samba_server start
service samba_server restart