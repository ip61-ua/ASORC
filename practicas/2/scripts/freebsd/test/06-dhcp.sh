#!/bin/bash

# Instalar dhcpclient
sudo dnf install -y dhclient

# Probarlo desde HOST (-d control por señales C-c)
sudo dhclient -d -v vboxnet0

# Podemos utilizar la configuración propuesta en el host
# Entonces desde el guest podemos hacer...
ping -c 2 192.168.25.101
