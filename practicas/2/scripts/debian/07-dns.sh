#!/bin/bash

# --- Limpieza del estado anterior ---
systemctl stop bind9
apt purge bind9 bind9utils -y
rm -rf /etc/bind/

# Instalación 
apt install -y bind9 bind9utils

# Configuración globales
cat << 'EOF' > /etc/bind/named.conf.options
options {
	directory "/var/cache/bind";

	listen-on port 53 { 127.0.0.1; 192.168.25.10; };

	forwarders {
		193.145.233.6;
		193.145.233.5;
	};
	forward first;
	dnssec-validation no;
	auth-nxdomain no;
	allow-query { localhost; 192.168.25.0/24; };
};
EOF

# Declaración de zonas locales
# 1. Zona directa cambiada a "debian.asorc.org"
# 2. Zona inversa
cat << 'EOF' > /etc/bind/named.conf.local
zone "debian.asorc.org" {
	type master;
	file "/etc/bind/db.debian.asorc.org";
};


zone "25.168.192.in-addr.arpa" {
	type master;
	file "/etc/bind/db.192.168.25";
};
EOF

# Zona directa
cat << 'EOF' > /etc/bind/db.debian.asorc.org
$TTL 604800
@   IN  SOA     ns.debian.asorc.org. root.debian.asorc.org. (
2         ; Serial
604800         ; Refresh
86400         ; Retry
2419200         ; Expire
604800 )       ; Negative Cache TTL
;
; Servidor de Nombres (NS)
@   IN  NS      ns.debian.asorc.org.

; Registros A (Direcciones IP)
@       IN  A   192.168.25.10
ns      IN  A   192.168.25.10
host    IN  A   192.168.25.1
truenas IN  A   192.168.25.9
EOF

# Zona inversa
cat << 'EOF' > /etc/bind/db.192.168.25
$TTL 604800
@   IN  SOA     ns.debian.asorc.org. root.debian.asorc.org. (
1         ; Serial
604800         ; Refresh
86400         ; Retry
2419200         ; Expire
604800 )       ; Negative Cache TTL
;
; Servidor de Nombres (NS)
@   IN  NS      ns.debian.asorc.org.

; Registros PTR (IP -> Nombre)
10  IN  PTR     ns.debian.asorc.org.
1   IN  PTR     host.debian.asorc.org.
9   IN  PTR     truenas.debian.asorc.org.
EOF

# Aplicar cambios y reiniciar servicio 
systemctl daemon-reload
systemctl restart bind9
systemctl enable bind9
rndc querylog on

# Validación de sintaxis
named-checkconf
named-checkzone debian.asorc.org /etc/bind/db.debian.asorc.org
named-checkzone 25.168.192.in-addr.arpa /etc/bind/db.192.168.25

# Usar DNS local
echo "nameserver 127.0.0.1" > /etc/resolv.conf.head

# Comprobaciones desde el guest (MODIFICADO) 
systemctl status bind9 --no-pager
# Prueba de la nueva zona
nslookup debian.asorc.org
nslookup www.ua.es

# Sobreescribir temporalmente.
echo "nameserver 127.0.0.1" > /etc/resolv.conf