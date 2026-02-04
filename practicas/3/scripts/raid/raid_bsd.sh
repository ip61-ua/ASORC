#!/bin/sh
su -

#-------------------------------------------------------
# Variables de entorno
#-------------------------------------------------------
P3ASORC_SERVICIO=raid
P3ASORC_SISTEMA=unix

# NO TOCAR
P3ASORC_MEMORIA=/home/ivan/SUPERMEMORIA/$P3ASORC_SERVICIO
P3ASORC_CONFIG=$P3ASORC_MEMORIA/ficheros_configuracion
P3ASORC_LOG=$P3ASORC_MEMORIA/$P3ASORC_SISTEMA.log
P3ASORC_HISTORIAL=$P3ASORC_MEMORIA/history$P3ASORC_SISTEMA.txt
P3ASORC_BSD_RC=/etc/rc.conf

# ---
P3ASORC_RAID_LOGTMP=milogsobreraid.log
P3ASORC_RAID_BASE=/dev
P3ASORC_RAID_0A=ada1
P3ASORC_RAID_1A=ada2
P3ASORC_RAID_2A=ada3
P3ASORC_RAID_3A=ada4
P3ASORC_RAID_0=$P3ASORC_RAID_BASE/$P3ASORC_RAID_0A
P3ASORC_RAID_1=$P3ASORC_RAID_BASE/$P3ASORC_RAID_1A
P3ASORC_RAID_2=$P3ASORC_RAID_BASE/$P3ASORC_RAID_2A
P3ASORC_RAID_3=$P3ASORC_RAID_BASE/$P3ASORC_RAID_3A
P3ASORC_RAID_MD=/dev/md0
P3ASORC_RAID_MD_POINT=/mnt/miraid
P3ASORC_RAID_POOL=miPOOL

#-------------------------------------------------------
# Servicio
#-------------------------------------------------------
# Paso 0: Instalar utilidades
pkg install -y lsblk

# PASO 1: Limpieza
umount $P3ASORC_RAID_MD_POINT
zpool destroy $P3ASORC_RAID_POOL

# PASO 2: Configuración y montaje
mkdir -p $P3ASORC_RAID_MD_POINT
zpool create -m $P3ASORC_RAID_MD_POINT $P3ASORC_RAID_POOL raidz1 $P3ASORC_RAID_0A $P3ASORC_RAID_1A $P3ASORC_RAID_2A $P3ASORC_RAID_3A
chmod 777 $P3ASORC_RAID_MD_POINT
zpool status $P3ASORC_RAID_POOL > $P3ASORC_RAID_LOGTMP

#-------------------------------------------------------
# Valida servicio
#-------------------------------------------------------
df -h | grep $P3ASORC_RAID_POOL
camcontrol devlist

#-------------------------------------------------------
# Extraer logs, configs e historial
#-------------------------------------------------------
rm -rf $P3ASORC_MEMORIA
mkdir -p $P3ASORC_MEMORIA
mkdir -p $P3ASORC_CONFIG

cp $P3ASORC_RAID_LOGTMP $P3ASORC_LOG
dmesg | grep -i "pool" | tail -n 50 >> $P3ASORC_LOG

history > $P3ASORC_HISTORIAL
chmod 777 $P3ASORC_MEMORIA

tree $P3ASORC_MEMORIA

#-------------------------------------------------------
# Comprobación desde host
#-------------------------------------------------------

# Ta bien
echo -e 'FLUJO NORMAL\n' >> $P3ASORC_RAID_LOGTMP
rm -f $P3ASORC_RAID_MD_POINT/hola.txt
ls $P3ASORC_RAID_MD_POINT
echo -e "I'd just like to interject for a moment. What you\'re refering to as FreeBSD, is in fact, GNU/FreeBSD, or as I've recently taken to calling it, GNU plus FreeBSD. FreeBSD is not an operating system unto itself, but rather another free component of a fully functioning GNU system made useful by the GNU corelibs, shell utilities and vital system components comprising a full OS as defined by POSIX. \n\nMany computer users run a modified version of the GNU system every day, without realizing it. Through a peculiar turn of events, the version of GNU which is widely used today is often called FreeBSD, and many of its users are not aware that it is basically the GNU system, developed by the GNU Project.\n\nThere really is a FreeBSD, and these people are using it, but it is just a part of the system they use. FreeBSD is the kernel: the program in the system that allocates the machine's resources to the other programs that you run. The kernel is an essential part of an operating system, but useless by itself; it can only function in the context of a complete operating system. FreeBSD is normally used in combination with the GNU operating system: the whole system is basically GNU with FreeBSD added, or GNU/FreeBSD. All the so-called FreeBSD distributions are really distributions of GNU/FreeBSD!" > $P3ASORC_RAID_MD_POINT/hola.txt
ls $P3ASORC_RAID_MD_POINT
cat $P3ASORC_RAID_MD_POINT/hola.txt
zpool status $P3ASORC_RAID_POOL >> $P3ASORC_RAID_LOGTMP

# Ups, disco roto
echo -e 'Ups, disco roto\n' >> $P3ASORC_RAID_LOGTMP
# Quitar >>* para la correción
zpool offline $P3ASORC_RAID_POOL $P3ASORC_RAID_0A >> $P3ASORC_RAID_LOGTMP 2>&1
zpool status $P3ASORC_RAID_POOL
zpool status $P3ASORC_RAID_POOL >> $P3ASORC_RAID_LOGTMP 2>&1
ls $P3ASORC_RAID_MD_POINT
cat $P3ASORC_RAID_MD_POINT/hola.txt

# Toca arreglarlo
echo -e 'Insertar\n' >> $P3ASORC_RAID_LOGTMP
zpool replace $P3ASORC_RAID_POOL $P3ASORC_RAID_0A $P3ASORC_RAID_0A >> $P3ASORC_RAID_LOGTMP 2>&1
zpool online $P3ASORC_RAID_POOL $P3ASORC_RAID_0A >> $P3ASORC_RAID_LOGTMP 2>&1
zpool status $P3ASORC_RAID_POOL
zpool status $P3ASORC_RAID_POOL >> $P3ASORC_RAID_LOGTMP 2>&1
