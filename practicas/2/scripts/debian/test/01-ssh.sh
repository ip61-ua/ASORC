#!/bin/bash

# CONFIGURACION CLAVE
sudo rm -f ~/.ssh/known_hosts /etc/ssh/ssh_host*
ssh-keygen -t rsa
ssh-copy-id ivan@192.168.25.10

# PROBAR SSH
ssh ivan@192.168.25.10 "uname -a"

# PROBAR SCP
echo "Hola XX" > ~/prueba_XX.txt
scp ~/prueba_XX.txt ivan@192.168.25.10:~/
scp ivan@192.168.25.10:~/prueba_XX.txt ~/prueba_XX2.txt
diff -q ~/prueba_XX.txt ~/prueba_XX2.txt && echo "COINCIDEN."
rm ~/prueba_XX.txt ~/prueba_XX2.txt

# PROBAR SFTP
sftp ivan@192.168.25.10
# ls
# lls
