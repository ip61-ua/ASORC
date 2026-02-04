#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Se necesitan privilegios de administrador."
  pkexec "$0" "$@"
  exit $?
fi

# ---- NFS ----
dnf install -y nfs-utils

# DESCUBRIR
showmount -e 192.168.25.11

# MONTAR CARPETA
mkdir ~/NFS_MONTAO_BSD
sudo mount 192.168.25.11:/var/srv/nfs ~/NFS_MONTAO_BSD
ls ~/NFS_MONTAO_BSD
echo "Hola desde fedora para los usuarios de freebsd. Free como Freedom." > ~/NFS_MONTAO_BSD/test.txt

# DESMONTAR
sudo umount ~/NFS_MONTAO_BSD

# ---- SAMBA ----
# CONECTARSE
smbclient //192.168.25.11/publico -U ivan

# MONTAR CARPETA
mkdir ~/SAMBA_MONTAO_BSD
sudo mount -t cifs //192.168.25.11/publico /home/ibai/SAMBA_MONTAO_BSD -o username=ivan,uid=ibai,gid=ibai

# DESMONTAR
sudo umount ~/SAMBA_MONTAO_BSD