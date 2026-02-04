#!/bin/sh
su -

#-------------------------------------------------------
# Variables de entorno
#-------------------------------------------------------
P3ASORC_SERVICIO=raid
P3ASORC_SISTEMA=linux

# NO TOCAR
P3ASORC_MEMORIA=/home/ivan/SUPERMEMORIA/$P3ASORC_SERVICIO
P3ASORC_CONFIG=$P3ASORC_MEMORIA/ficheros_configuracion
P3ASORC_LOG=$P3ASORC_MEMORIA/$P3ASORC_SISTEMA.log
P3ASORC_HISTORIAL=$P3ASORC_MEMORIA/history$P3ASORC_SISTEMA.txt

# ---
P3ASORC_RAID_LOGTMP=milogsobreraid.log
P3ASORC_RAID_BASE=/dev
P3ASORC_RAID_0=$P3ASORC_RAID_BASE/sdb
P3ASORC_RAID_1=$P3ASORC_RAID_BASE/sdc
P3ASORC_RAID_2=$P3ASORC_RAID_BASE/sdd
P3ASORC_RAID_3=$P3ASORC_RAID_BASE/sde
P3ASORC_RAID_01=$P3ASORC_RAID_BASE/sdb1
P3ASORC_RAID_11=$P3ASORC_RAID_BASE/sdc1
P3ASORC_RAID_21=$P3ASORC_RAID_BASE/sdd1
P3ASORC_RAID_31=$P3ASORC_RAID_BASE/sde1
P3ASORC_RAID_MD=/dev/md0
P3ASORC_RAID_ORDER_FILE=createraid.txt
P3ASORC_RAID_DELETE_FILE=deletepartition.txt
P3ASORC_RAID_MD_POINT=/mnt/miraid

#-------------------------------------------------------
# Servicio
#-------------------------------------------------------
# PASO 1: Instala paquetes y limpieza
umount -f $P3ASORC_RAID_MD_POINT
mdadm --remove -S $P3ASORC_RAID_MD
umount -f $P3ASORC_RAID_01
umount -f $P3ASORC_RAID_11
umount -f $P3ASORC_RAID_21
umount -f $P3ASORC_RAID_31
umount -f $P3ASORC_RAID_0
umount -f $P3ASORC_RAID_1
umount -f $P3ASORC_RAID_2
umount -f $P3ASORC_RAID_3

apt remove -y mdadm
apt install -y mdadm

# PASO 2: Formato
# Averiguar qué dispositivos a formatear
lsblk

# Archivos de órdenes de formateo
cat << EOF > $P3ASORC_RAID_DELETE_FILE
d
w

EOF

cat << EOF > $P3ASORC_RAID_ORDER_FILE
n
p
1


t
raid
w

EOF

# Formatea
fdisk $P3ASORC_RAID_0 < $P3ASORC_RAID_DELETE_FILE
fdisk $P3ASORC_RAID_1 < $P3ASORC_RAID_DELETE_FILE
fdisk $P3ASORC_RAID_2 < $P3ASORC_RAID_DELETE_FILE
fdisk $P3ASORC_RAID_3 < $P3ASORC_RAID_DELETE_FILE

fdisk $P3ASORC_RAID_0 < $P3ASORC_RAID_ORDER_FILE
fdisk $P3ASORC_RAID_1 < $P3ASORC_RAID_ORDER_FILE
fdisk $P3ASORC_RAID_2 < $P3ASORC_RAID_ORDER_FILE
fdisk $P3ASORC_RAID_3 < $P3ASORC_RAID_ORDER_FILE

rm -rf $P3ASORC_RAID_ORDER_FILE $P3ASORC_RAID_DELETE_FILE

# PASO 3: Inicialización
# Crear RAID
echo -e 'y\n' | mdadm --create --verbose $P3ASORC_RAID_MD -l 5 -n 4 $P3ASORC_RAID_01 $P3ASORC_RAID_11 $P3ASORC_RAID_21 $P3ASORC_RAID_31 > $P3ASORC_RAID_LOGTMP 2>&1

# Sincronizar
mdadm --wait $P3ASORC_RAID_MD
mdadm --detail --verbose $P3ASORC_RAID_MD >> $P3ASORC_RAID_LOGTMP

# Montaje
mkfs.ext4 $P3ASORC_RAID_MD >> $P3ASORC_RAID_LOGTMP 2>&1
mkdir -p $P3ASORC_RAID_MD_POINT
mount $P3ASORC_RAID_MD $P3ASORC_RAID_MD_POINT
chmod 777 $P3ASORC_RAID_MD_POINT

#-------------------------------------------------------
# Valida servicio
#-------------------------------------------------------
mdadm --detail --verbose $P3ASORC_RAID_MD
cat /proc/mdstat
lsblk

#-------------------------------------------------------
# Extraer logs, configs e historial
#-------------------------------------------------------
rm -rf $P3ASORC_MEMORIA
mkdir -p $P3ASORC_MEMORIA
mkdir -p $P3ASORC_CONFIG

cp $P3ASORC_RAID_LOGTMP $P3ASORC_LOG
dmesg | grep -i "md" | tail -n 50 >> $P3ASORC_LOG
mdadm --detail --scan --verbose >> $P3ASORC_CONFIG/mdadm.conf

history > $P3ASORC_HISTORIAL
chmod 777 -R $P3ASORC_MEMORIA

tree $P3ASORC_MEMORIA

#-------------------------------------------------------
# Comprobación desde GUEST
#-------------------------------------------------------

# Ta bien
echo -e 'FLUJO NORMAL\n' >> $P3ASORC_RAID_LOGTMP
rm -f $P3ASORC_RAID_MD_POINT/hola.txt
ls $P3ASORC_RAID_MD_POINT
echo 'Hola desde ASORC' > $P3ASORC_RAID_MD_POINT/hola.txt
ls $P3ASORC_RAID_MD_POINT
cat $P3ASORC_RAID_MD_POINT/hola.txt
mdadm --detail --verbose $P3ASORC_RAID_MD >> $P3ASORC_RAID_LOGTMP

# Ups, disco roto
echo -e 'Ups, disco roto\n' >> $P3ASORC_RAID_LOGTMP
# Quitar >>* para la correción
mdadm --verbose -f $P3ASORC_RAID_MD $P3ASORC_RAID_01 >> $P3ASORC_RAID_LOGTMP 2>&1
mdadm --detail --verbose $P3ASORC_RAID_MD
mdadm --detail --verbose $P3ASORC_RAID_MD >> $P3ASORC_RAID_LOGTMP 2>&1
ls $P3ASORC_RAID_MD_POINT
cat $P3ASORC_RAID_MD_POINT/hola.txt

# Limpieza
echo -e 'Limpieza\n' >> $P3ASORC_RAID_LOGTMP
mdadm --manage $P3ASORC_RAID_MD --remove $P3ASORC_RAID_01
mdadm --zero-superblock $P3ASORC_RAID_01

# Toca arreglarlo
echo -e 'Insertar\n' >> $P3ASORC_RAID_LOGTMP
mdadm --add --verbose $P3ASORC_RAID_MD $P3ASORC_RAID_01 >> $P3ASORC_RAID_LOGTMP 2>&1
mdadm --detail --verbose $P3ASORC_RAID_MD
mdadm --detail --verbose $P3ASORC_RAID_MD >> $P3ASORC_RAID_LOGTMP 2>&1

# Espera a la reconstrucción
echo -e 'Espera a la reconstrucción\n' >> $P3ASORC_RAID_LOGTMP
mdadm --wait $P3ASORC_RAID_MD
mdadm --detail --verbose $P3ASORC_RAID_MD
mdadm --detail --verbose $P3ASORC_RAID_MD >> $P3ASORC_RAID_LOGTMP 2>&1
