#!/bin/sh
su -

# tar explicación
# -c: crear, -z: gzip, -v: verbose, -f: archivo, -p: preservar permisos
#-------------------------------------------------------
# Variables de entorno
#-------------------------------------------------------
P3ASORC_SERVICIO=backup
P3ASORC_SISTEMA=unix

# NO TOCAR
P3ASORC_MEMORIA=/home/ivan/SUPERMEMORIA/$P3ASORC_SERVICIO
P3ASORC_CONFIG=$P3ASORC_MEMORIA/ficheros_configuracion
P3ASORC_LOG=$P3ASORC_MEMORIA/$P3ASORC_SISTEMA.log
P3ASORC_HISTORIAL=$P3ASORC_MEMORIA/history$P3ASORC_SISTEMA.txt
P3ASORC_BSD_RC=/etc/rc.conf

# ---
P3ASORC_BACKUP_PREFIX=COPIA_ASORC_
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

# PASO 0: Instalación, limpieza y datos iniciales
pkg install -y rsync tree
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
# 1.a Copia Absoluta
tar -czvpf $P3ASORC_BACKUP_A_DST/$P3ASORC_BACKUP_PREFIX$(date +%F).tar.gz $P3ASORC_BACKUP_A_SRC > $P3ASORC_BACKUP_LOGFILE 2>&1

# 1.b Copia Diferencial
FECHA_AYER=$(date -v-1d +%F)
tar -czvpf $P3ASORC_BACKUP_D_DST/$P3ASORC_BACKUP_PREFIX$(date +%F).tar.gz $P3ASORC_BACKUP_D_SRC -N "$FECHA_AYER" >> $P3ASORC_BACKUP_LOGFILE 2>&1

# 1.c Copia Síncrona
rsync -av --delete $P3ASORC_BACKUP_S_SRC/ $P3ASORC_BACKUP_S_DST/ >> $P3ASORC_BACKUP_LOGFILE 2>&1

#-------------------------------------------------------
# PASO 2: SIMULAR DESASTRE (Modificamos los datos)
#-------------------------------------------------------
rm -f $P3ASORC_BACKUP_A_SRC/$P3ASORC_BACKUP_1
rm -f $P3ASORC_BACKUP_D_SRC/$P3ASORC_BACKUP_1
rm -f $P3ASORC_BACKUP_S_SRC/$P3ASORC_BACKUP_1

echo "$P3ASORC_BACKUP_2_CONTENT" > $P3ASORC_BACKUP_A_SRC/$P3ASORC_BACKUP_2
echo "$P3ASORC_BACKUP_2_CONTENT" > $P3ASORC_BACKUP_D_SRC/$P3ASORC_BACKUP_2
echo "$P3ASORC_BACKUP_2_CONTENT" > $P3ASORC_BACKUP_S_SRC/$P3ASORC_BACKUP_2

#-------------------------------------------------------
# PASO 3: RESTAURAR
#-------------------------------------------------------
rm -rf $P3ASORC_BACKUP_A_SRC/*
rm -rf $P3ASORC_BACKUP_D_SRC/*
rm -rf $P3ASORC_BACKUP_S_SRC/*

# 3.a Restauración Absoluta
P3ASORC_BACKUP_ARCHIVO_ABSOLUTO=$(ls -t $P3ASORC_BACKUP_A_DST/*.tar.gz | head -1)
tar -xzvf $P3ASORC_BACKUP_ARCHIVO_ABSOLUTO -C / >> $P3ASORC_BACKUP_LOGFILE 2>&1

# 3.b Restauración Diferencial
P3ASORC_BACKUP_ARCHIVO_DIFERENCIAL=$(ls -t $P3ASORC_BACKUP_D_DST/*.tar.gz | head -1)
tar -xzvf $P3ASORC_BACKUP_ARCHIVO_DIFERENCIAL -C / >> $P3ASORC_BACKUP_LOGFILE 2>&1

# 3.c Restauración Síncrona
rsync -av --delete $P3ASORC_BACKUP_S_DST/ $P3ASORC_BACKUP_S_SRC/ >> $P3ASORC_BACKUP_LOGFILE 2>&1

#-------------------------------------------------------
# PASO 4: VER FINAL
#-------------------------------------------------------
tree $P3ASORC_BACKUP_PLACE

#-------------------------------------------------------
# PASO 5: CRON (Hacer backup los domingos a las 3am)
#-------------------------------------------------------
crontab -l > $P3ASORC_BACKUP_CRONFILE 2>/dev/null
echo "0 3 * * 0 tar -czpf $P3ASORC_BACKUP_A_DST/FULL_\$(date +\%F).tar.gz $P3ASORC_BACKUP_A_SRC" >> $P3ASORC_BACKUP_CRONFILE
echo "0 3 * * 0 rsync -av --delete $P3ASORC_BACKUP_S_SRC/ $P3ASORC_BACKUP_S_DST/" >> $P3ASORC_BACKUP_CRONFILE
crontab $P3ASORC_BACKUP_CRONFILE

#-------------------------------------------------------
# Valida servicio
#-------------------------------------------------------
service cron status
ls -lR $P3ASORC_BACKUP_PLACE | grep tar.gz
crontab -l

#-------------------------------------------------------
# Extraer logs, configs e historial
#-------------------------------------------------------
rm -rf $P3ASORC_MEMORIA
mkdir -p $P3ASORC_MEMORIA
mkdir -p $P3ASORC_CONFIG

cp $P3ASORC_BACKUP_LOGFILE $P3ASORC_LOG
cp $P3ASORC_BACKUP_CRONFILE $P3ASORC_CONFIG/crontab_dump.txt
cp $P3ASORC_BSD_RC $P3ASORC_CONFIG/rc.conf

history > $P3ASORC_HISTORIAL
chmod 777 -R $P3ASORC_MEMORIA

tree $P3ASORC_MEMORIA
