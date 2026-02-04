#!/bin/bash

# Habilitar servicio
sysrc dhcpd_enable="YES"

# Restringir zona de operación en DCHP a la interfaz Host Only
sysrc dhcpd_ifaces="em1"

# Prototipar respuesta DHCP
# - Dar una IP dentro de unos rangos
# - Máscara, dir. broadcast, tiempo de libreación
cat << 'EOF' > /usr/local/etc/dhcpd.conf
log-facility local7;
authoritative;

subnet 192.168.25.0 netmask 255.255.255.0 {
  range 192.168.25.101 192.168.25.150;
  option routers 192.168.25.1;
  option domain-name-servers 192.168.25.11;
  option domain-name "debian2.local";
  option subnet-mask 255.255.255.0;
  option broadcast-address 192.168.25.255;
  default-lease-time 600;
  max-lease-time 7200;
}
EOF

cat << 'EOF' > /etc/syslog.conf
local7.* /var/log/dhcpd.log
EOF

touch /var/log/dhcpd.log

# Reiniciar servicio para aplicar cambios
service syslogd restart
service isc-dhcpd restart