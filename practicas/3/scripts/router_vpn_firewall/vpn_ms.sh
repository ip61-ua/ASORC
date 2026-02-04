#!/bin/sh

# Característica VPN
Install-WindowsFeature DirectAccess-VPN -IncludeManagementTools

# Manejador de enrutamiento y VPN
rrasmgmt.msc

# Adminstración de grupos y usuarios
lusrmgr.msc

# Mata al proceso que estorba (no es necesario hacer)
Stop-Process -Id $(Get-NetUDPEndpoint -LocalPort 123 | Select-ObjectOwningProcess).OwningProcess -Force

# Obtener info de dicho proceso
Get-NetUDPEndpoint -LocalPort 123

# Abrir puerto TCP 1723 (Control PPTP)
New-NetFirewallRule -DisplayName "Permitir PPTP-TCP" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 1723

# Abrir Protocolo GRE 47 (Tunel de datos)
New-NetFirewallRule -DisplayName "Permitir GRE-47" -Direction Inbound -Action Allow -Protocol 123

# Ver actividad del servicio
netstat -an | findstr 1723

#-------------------------------------------------------
# Comprobación desde host
#-------------------------------------------------------

# En una terminal
sudo journalctl -f | grep pppd

# Sin conctarse
ping 192.168.25.200
ping 192.168.25.201

# Conectarse desde la bandeja
ping 192.168.25.200
ping 192.168.25.201