#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Se necesitan privilegios de administrador."
  pkexec "$0" "$@"
  exit $?
fi

# ---- NFS ----
dnf install -y nfs-utils

# DESCUBRIR
showmount -e 192.168.25.10

# MONTAR CARPETA
mkdir ~/NFS_MONTAO
sudo mount 192.168.25.10:/srv/nfs ~/NFS_MONTAO
ls ~/NFS_MONTAO
echo "Hola desde fedora" > ~/NFS_MONTAO/test.txt

# DESMONTAR
sudo umount ~/NFS_MONTAO

# ---- SAMBA ----
# CONECTARSE
smbclient //192.168.25.10/publico -U ivan

# MONTAR CARPETA
mkdir ~/SAMBA_MONTAO
sudo mount -t cifs -o username=ivan //192.168.25.10/publico ~/SAMBA_MONTAO

# DESMONTAR
sudo umount ~/SAMBA_MONTAO