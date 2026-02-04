#!/bin/bash

# Instalar el servidor DHCP
apt install isc-dhcp-server

# Restringir zona de operación en DCHP a la interfaz Host Only
cat << 'EOF' > /etc/default/isc-dhcp-server
INTERFACESv4="enp0s8"

EOF

# Prototipar respuesta DHCP
# - Dar una IP dentro de unos rangos
# - Máscara, dir. broadcast, tiempo de libreación
cat << 'EOF' > /etc/dhcp/dhcpd.conf
authoritative;

subnet 192.168.25.0 netmask 255.255.255.0 {
  range 192.168.25.51 192.168.25.100;
  option routers 192.168.25.1;
  option domain-name-servers 192.168.25.10;
  option domain-name "debian2.local";
  option subnet-mask 255.255.255.0;
  option broadcast-address 192.168.25.255;
  default-lease-time 600;
  max-lease-time 7200;
}
EOF

# Reiniciar servicio para aplicar cambios
systemctl restart isc-dhcp-server