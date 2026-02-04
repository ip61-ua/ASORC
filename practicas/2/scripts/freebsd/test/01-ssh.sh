#!/bin/bash

# CONFIGURACION CLAVE
# (solo si se hace por primera vez)
sudo rm -f ~/.ssh/known_hosts /etc/ssh/ssh_host*
ssh-keygen -t rsa
# Esto es clave
ssh-copy-id ivan@192.168.25.11

# PROBAR SSH
ssh ivan@192.168.25.11 "uname -a"

# PROBAR SCP
echo "Hola BSD" > ~/prueba_XX.txt
scp ~/prueba_XX.txt ivan@192.168.25.11:~/
scp ivan@192.168.25.11:~/prueba_XX.txt ~/prueba_XX2.txt
diff -q ~/prueba_XX.txt ~/prueba_XX2.txt && echo "COINCIDEN."
rm ~/prueba_XX.txt ~/prueba_XX2.txt

# PROBAR SFTP
sftp ivan@192.168.25.11
# ls
# lls
