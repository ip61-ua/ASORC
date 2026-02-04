#!/bin/bash

# ---- GIT ----
# Host
cd Escritorio/
git clone ssh://ivan@192.168.25.10:22/srv/git/practica.git
cd practica/
touch app.js
echo 'console.log("HOLA DESDE FEDORA A DEBIAN ASORC")' > app.js
cat app.js
git add .
git commit -am "Mi primer commit desde Fedora para Debian"
git push
touch __init__.py
git add .
git commit -am "Segundo commit"
git push

# Guest
git config --global
git log

# ---- NEXTCLOUD ----
firefox nextdebian.org