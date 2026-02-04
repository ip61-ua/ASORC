#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Se necesitan privilegios de administrador."
  pkexec "$0" "$@"
  exit $?
fi

echo '# Loopback entries; do not change.
# For historical reasons, localhost precedes localhost.localdomain:
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
# See hosts(5) for proper format and other examples:
# 192.168.1.10 foo.example.org foo
# 192.168.1.13 bar.example.org bar
192.168.25.10   nextdebian.org dbdebian.org web1debian.org web2debian.org
192.168.25.11   nextbsd.org dbbsd.org web1bsd.org web2bsd.org
192.168.25.12   nextms.org dbms.org web1ms.org web2ms.org' > /etc/hosts

CON_NAME="vboxnet0"
IF_NAME="vboxnet0"
IP_CONFIG="192.168.25.1/24"

if nmcli con show "$CON_NAME" &> /dev/null; then
    nmcli con modify "$CON_NAME" \
        ifname "$IF_NAME" \
        ipv4.method "manual" \
        ipv4.address "$IP_CONFIG" \
        ipv6.method "ignore"
else
    nmcli con add \
        type "ethernet" \
        con-name "$CON_NAME" \
        ifname "$IF_NAME" \
        ipv4.method "manual" \
        ipv4.address "$IP_CONFIG" \
        ipv6.method "ignore"
fi

nmcli con up "$CON_NAME"
