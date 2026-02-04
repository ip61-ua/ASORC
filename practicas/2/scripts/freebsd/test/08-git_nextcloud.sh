#!/bin/bash

# ---- GIT ----
# Host
cd Escritorio/
git clone ssh://ivan@192.168.25.11:22/var/srv/git/practica2.git
cd practica2/
touch app.js
echo 'console.log("HOLA DESDE FEDORA A BSD ASORC")' > app.js
cat app.js
git add .
git commit -am "Mi primer commit desde Fedora para BSD"
git push
touch __init__.py
git add .
git commit -am "Segundo commit"
git push

# Guest
git config --global
git log

# ---- NEXTCLOUD ----
firefox nextbsd.org