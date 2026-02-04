#!/bin/sh

##### DESCARGAR EL MYSYS2
powershell
C:/msys64/msys2_shell.cmd -defterm -here -no-start -ucrt64

# tar explicación
# -c: crear, -z: gzip, -v: verbose, -f: archivo, -p: preservar permisos
#-------------------------------------------------------
# Variables de entorno
#-------------------------------------------------------
P3ASORC_BACKUP_PREFIX=COPIA_ASORC_
# Nota: /var/COPIAS estará dentro de C:\msys64\var\COPIAS
P3ASORC_BACKUP_PLACE=/var/COPIAS
P3ASORC_BACKUP_1=1.txt
P3ASORC_BACKUP_1_CONTENT=Hola
P3ASORC_BACKUP_2=2.txt
P3ASORC_BACKUP_2_CONTENT=Adios
P3ASORC_BACKUP_LOGFILE=$P3ASORC_BACKUP_PLACE/personalizado_backup.log
P3ASORC_BACKUP_CRONFILE=$P3ASORC_BACKUP_PLACE/crontab_backup
P3ASORC_BACKUP_A_SRC=$P3ASORC_BACKUP_PLACE/a
P3ASORC_BACKUP_A_DST=$P3ASORC_BACKUP_PLACE/a_dst
P3ASORC_BACKUP_D_SRC=$P3ASORC_BACKUP_PLACE/d
P3ASORC_BACKUP_D_DST=$P3ASORC_BACKUP_PLACE/d_dst
P3ASORC_BACKUP_S_SRC=$P3ASORC_BACKUP_PLACE/s
P3ASORC_BACKUP_S_DST=$P3ASORC_BACKUP_PLACE/s_dst

#-------------------------------------------------------
# Servicio
#-------------------------------------------------------
# PASO 0: Limpieza y datos iniciales
pacman -S --noconfirm --needed rsync tree tar
rm -rf $P3ASORC_BACKUP_PLACE
mkdir -p $P3ASORC_BACKUP_A_SRC
mkdir -p $P3ASORC_BACKUP_A_DST
mkdir -p $P3ASORC_BACKUP_D_SRC
mkdir -p $P3ASORC_BACKUP_D_DST
mkdir -p $P3ASORC_BACKUP_S_SRC
mkdir -p $P3ASORC_BACKUP_S_DST

echo "$P3ASORC_BACKUP_1_CONTENT" > $P3ASORC_BACKUP_A_SRC/$P3ASORC_BACKUP_1
echo "$P3ASORC_BACKUP_1_CONTENT" > $P3ASORC_BACKUP_D_SRC/$P3ASORC_BACKUP_1
echo "$P3ASORC_BACKUP_1_CONTENT" > $P3ASORC_BACKUP_S_SRC/$P3ASORC_BACKUP_1

#-------------------------------------------------------
# PASO 1: REALIZAR BACKUPS
#-------------------------------------------------------
# 1.a Copia absoluta
tar -czvpf $P3ASORC_BACKUP_A_DST/$P3ASORC_BACKUP_PREFIX$(date +%F).tar.gz $P3ASORC_BACKUP_A_SRC > $P3ASORC_BACKUP_LOGFILE

# 1.b Copia diferencial
tar -czvpf $P3ASORC_BACKUP_D_DST/$P3ASORC_BACKUP_PREFIX$(date +%F).tar.gz $P3ASORC_BACKUP_D_SRC -N "$(date -d 'yesterday' +%F)" >> $P3ASORC_BACKUP_LOGFILE

# 1.c Copia síncrona
rsync -av --delete $P3ASORC_BACKUP_S_SRC/ $P3ASORC_BACKUP_S_DST/ >> $P3ASORC_BACKUP_LOGFILE

#-------------------------------------------------------
# PASO 2: SIMULAR DESASTRE (Modificamos los datos)
#-------------------------------------------------------
rm -f $P3ASORC_BACKUP_A_SRC/$P3ASORC_BACKUP_1
rm -f $P3ASORC_BACKUP_D_SRC/$P3ASORC_BACKUP_1
rm -f $P3ASORC_BACKUP_S_SRC/$P3ASORC_BACKUP_1

echo "$P3ASORC_BACKUP_2_CONTENT" > $P3ASORC_BACKUP_A_SRC/$P3ASORC_BACKUP_2
echo "$P3ASORC_BACKUP_2_CONTENT" > $P3ASORC_BACKUP_D_SRC/$P3ASORC_BACKUP_2
echo "$P3ASORC_BACKUP_2_CONTENT" > $P3ASORC_BACKUP_S_SRC/$P3ASORC_BACKUP_2

tree $P3ASORC_BACKUP_PLACE

#-------------------------------------------------------
# PASO 3: RESTAURAR
#-------------------------------------------------------
rm -rf $P3ASORC_BACKUP_A_SRC/*
rm -rf $P3ASORC_BACKUP_D_SRC/*
rm -rf $P3ASORC_BACKUP_S_SRC/*

# 3.a Restauración absoluta
P3ASORC_BACKUP_ARCHIVO_ABSOLUTO=$(ls -t $P3ASORC_BACKUP_A_DST/*.tar.gz | head -1)
tar -xzvf $P3ASORC_BACKUP_ARCHIVO_ABSOLUTO -C / >> $P3ASORC_BACKUP_LOGFILE 2>&1

# 3.b Restauración diferencial
P3ASORC_BACKUP_ARCHIVO_DIFERENCIAL=$(ls -t $P3ASORC_BACKUP_D_DST/*.tar.gz | head -1)
tar -xzvf $P3ASORC_BACKUP_ARCHIVO_DIFERENCIAL -C / >> $P3ASORC_BACKUP_LOGFILE 2>&1

# 3.c Restauración síncrona
rsync -av --delete $P3ASORC_BACKUP_S_DST/ $P3ASORC_BACKUP_S_SRC/ >> $P3ASORC_BACKUP_LOGFILE 2>&1

#-------------------------------------------------------
# PASO 4: VER FINAL
#-------------------------------------------------------
tree $P3ASORC_BACKUP_PLACE

echo "Copiar $P3ASORC_BACKUP_LOGFILE"