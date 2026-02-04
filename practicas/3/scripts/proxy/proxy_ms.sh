#!/bin/sh
D:\Squid\bin\squid.exe -z
netsh interface portproxy add v4tov4 listenport=80 listenaddress=192.168.25.12 connectport=3129 connectaddress=127.0.0.1
netsh interface portproxy reset
netsh interface portproxy show all

#-------------------------------------------------------
# Comprobación
#-------------------------------------------------------
HTTPS_PROXY=192.168.25.12:3128 HTTP_PROXY=192.168.25.12:3128 curl -I https://www.laliga.com
HTTPS_PROXY=192.168.25.12:3128 HTTP_PROXY=192.168.25.12:3128 curl -I https://nodejs.org
