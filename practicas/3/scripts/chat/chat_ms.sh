#!/bin/sh

#Enable-WindowsOptionalFeature -Online -FeatureName Containers
#wsl --install
#winget install pidgin Docker.DockerDesktop
# CAMBIAR HOST=msasorcorg
# CAMBIAR PASSWORD=1

winget install Oracle.JDK.25
# Descargar el instalador desde aquí https://www.igniterealtime.org/downloads/
# Hacer lo típico de siguiente siguiente siguiente e instalar

#-------------------------------------------------------
# Comprobación desde host
#-------------------------------------------------------
sudo dnf install -y pidgin

pidgin -m
