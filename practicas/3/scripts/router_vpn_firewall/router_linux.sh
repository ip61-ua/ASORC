#!/bin/sh
su -

#-------------------------------------------------------
# Variables de entorno
#-------------------------------------------------------
P3ASORC_SERVICIO=router_vpn_firewall
P3ASORC_SISTEMA=linux

# NO TOCAR
P3ASORC_MEMORIA=/home/ivan/SUPERMEMORIA/$P3ASORC_SERVICIO
P3ASORC_CONFIG=$P3ASORC_MEMORIA/ficheros_configuracion
P3ASORC_LOG=$P3ASORC_MEMORIA/$P3ASORC_SISTEMA.log
P3ASORC_HISTORIAL=$P3ASORC_MEMORIA/history$P3ASORC_SISTEMA.txt

# ---
P3ASORC_ROUTER_CONFIG=/etc/sysctl.conf
P3ASORC_ROUTER_ILAN=enp0s8
P3ASORC_ROUTER_IWAN=enp0s3

#-------------------------------------------------------
# Servicio
#-------------------------------------------------------
# Requisitos tener hecho el dhcp de a antes
# PASO 0: Instalar paquetes
apt install -y iptables-persistent

# PASO 1: Aplicar forwarding
cat << EOF > $P3ASORC_ROUTER_CONFIG
net.ipv4.ip_forward=1
EOF

# PASO 2: Usar NAT
# Habilitar NAT (Masquerade) en la interfaz de salida
iptables -t nat -A POSTROUTING -o $P3ASORC_ROUTER_IWAN -j MASQUERADE

# Permitir tráfico desde la LAN hacia INTERNET
iptables -A FORWARD -i $P3ASORC_ROUTER_ILAN -o $P3ASORC_ROUTER_IWAN -j ACCEPT

# Permitir que la respuesta de internet vuelva a entrar hacia la LAN
iptables -A FORWARD -i $P3ASORC_ROUTER_IWAN -o $P3ASORC_ROUTER_ILAN -m state --state RELATED,ESTABLISHED -j ACCEPT

# PASO 3: Garantir persistencia
netfilter-persistent save

#-------------------------------------------------------
# Valida servicio
#-------------------------------------------------------
sysctl -p
ss -tulpn | grep :53
ss -tulpn | grep :67

#-------------------------------------------------------
# Extraer logs, configs e historial
#-------------------------------------------------------
rm -rf $P3ASORC_MEMORIA
mkdir -p $P3ASORC_MEMORIA
mkdir -p $P3ASORC_CONFIG

journalctl --no-pager --since=today | grep iptables > $P3ASORC_LOG
cp $P3ASORC_ROUTER_CONFIG $P3ASORC_CONFIG

history > $P3ASORC_HISTORIAL
chmod 777 -R $P3ASORC_MEMORIA

tree $P3ASORC_MEMORIA

#-------------------------------------------------------
# Comprobación desde host
#-------------------------------------------------------

# HACK: Con esto añadimos otra ip a la misma interfaz
sudo ip addr add 192.168.25.99/24 dev vboxnet0
sudo ip route add default via 192.168.25.10 table 100
sudo ip rule add from 192.168.25.99 table 100
ip a

# TEST
ping -c 1 -I 192.168.25.99 192.168.25.1
ping -c 2 -I 192.168.25.99 1.1.1.1
ping -c 3 -I 192.168.25.99 gnu.org
traceroute -I -s 192.168.25.99 192.168.25.1
traceroute -I -s 192.168.25.99 1.1.1.1
traceroute -I -s 192.168.25.99 gnu.org
