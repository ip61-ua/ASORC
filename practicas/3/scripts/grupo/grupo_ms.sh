#!/bin/sh

powershell -c "& ([ScriptBlock]::Create((irm 'https://www.php.net/include/download-instructions/windows.ps1'))) -Version 8.5"
# Descargar e instalar https://dev.mysql.com/get/Downloads/MySQL-9.5/mysql-9.5.0-winx64.msi

#-------------------------------------------------------
# Comprobación desde host
#-------------------------------------------------------
