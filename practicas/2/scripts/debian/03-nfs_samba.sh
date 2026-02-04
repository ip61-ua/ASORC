#!/bin/bash

# --- Configuración de NFS ---
# Instala el servidor NFS
apt install nfs-kernel-server

# Activa el log verboso (debug)
rpcdebug -m rpc -s all
rpcdebug -m nfs -s all

# Crea el directorio que se va a compartir y dar todos los permisos
mkdir -p /srv/nfs
chmod 777 /srv/nfs

# Sobrescribe /etc/exports para compartir /srv/nfs con la red 192.168.25.0/24
chmod 777 /etc/exports
echo "/srv/nfs  192.168.25.0/24(rw,sync,no_subtree_check)" > /etc/exports

# Aplica la configuración del fichero /etc/exports
exportfs -a

# Reinicia el servidor NFS
systemctl restart nfs-kernel-server

# --- Configuración de SAMBA ---

# Crea el directorio para la compartición de Samba y permisos
mkdir -p /srv/samba
chmod 777 /srv/samba

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
   path = /srv/samba
   read only = no
   browsable = yes
   valid users = ivan' > /etc/samba/smb.conf

# Reinicia el servicio Samba
systemctl restart smbd

# Establece la contraseña de Samba para el usuario 'ivan' a "1"
echo -e '1
1
' | smbpasswd -a ivan

# Aplicar cambios
systemctl restart smbd