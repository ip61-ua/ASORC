#!/bin/sh
#-------------------------------------------------------
# Comprobación desde host
#-------------------------------------------------------
sudo dnf install -y lftp

cat << EOF
rm -f hola.txt
ls
put hola.txt
ls
pwd
cd ..
pwd
quit
EOF

lftp -u usuario_jaula,PatataCaliente123 192.168.25.12
lftp -u usuario_libre,PatataCaliente123 -e "cd LocalUser/usuario_libre" 192.168.25.12
