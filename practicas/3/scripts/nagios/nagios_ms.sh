#!/bin/sh

$Cert = New-SelfSignedCertificate -DnsName "msasorcorg" -KeyAlgorithm RSA -KeyLength 2048 -CertStoreLocation "Cert:\LocalMachine\My" -NotAfter (Get-Date).AddYears(10) -KeyExportPolicy Exportable -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider"
$Thumbprint = $Cert.Thumbprint
$KeyPath = $Cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
$KeyPathFull = "$env:ProgramData\Microsoft\Crypto\RSA\MachineKeys\$KeyPath"
$NetworkServiceSid = [System.Security.Principal.SecurityIdentifier]::new([System.Security.Principal.WellKnownSidType]::NetworkServiceSid, $null)
$Acl = Get-Acl $KeyPathFull
$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($NetworkServiceSid, "Read", "Allow")
$Acl.SetAccessRule($Ar)
Set-Acl $KeyPathFull $Acl
Export-Certificate -Cert $Cert -FilePath "C:\msasorcorg.cer"
Import-Certificate -FilePath "C:\msasorcorg.cer" -CertStoreLocation "Cert:\LocalMachine\Root"

# Descargar WAC desde https://www.microsoft.com/es-es/evalcenter/download-windows-admin-center o bien buscar la aplicación Windows Center Admin (que posiblemente esté prehinstalada)
# Aceptar términos y condiciones del servicio.
# Elegir instalación personalizada
# Establecer que el acceso a red es remoto también
# Establecer la autenticación por etiquetas HTML de formulario
# Puerto de ecucha: 443
# Usar un certificado TLS y poner el contenido de la variable $RawCert
# Dejar FQDN por defecto
# Permitir el acceso desde cualquier ordenador
# Usar https
# Quitar las actualizaciones automáticas
# Establecer que la recolección espía de Microsoft sea solo de datos necesarios
# Instalar

Set-Item WSMan:\localhost\Client\TrustedHosts -Value '*' -Force
Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value
"127.0.0.1 msasorcorg"
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0" -Name "BackConnectionHostNames" -Value "msasorcorg" -PropertyType MultiString -Force
$WacService = Get-Service | Where-Object {$_.DisplayName -like "*Windows Admin Center*" -or $_.Name -like "*Sme*"}

if ($WacService) {
    Write-Host "Servicio encontrado: $($WacService.Name)" -ForegroundColor Green
    Write-Host "Reiniciando..."
    Restart-Service -Name $WacService.Name -Force
    Write-Host "Servicio reiniciado correctamente." -ForegroundColor Green
} else {
    Write-Host "No he encontrado el servicio. Es posible que WAC no se instalara como servicio." -ForegroundColor Red
}

# Instalar certificado C:\msasorcorg.cer
# En el Equipo local (Local Machine) y "Colocar todos los certificados en el siguiente almacén".
# Para luego pulsar "Examinar" y eligir la segunda carpeta: Entidades de certificación raíz de confianza (Trusted Root Certification Authorities).

Stop-Service WindowsAdminCenter -Force -ErrorAction SilentlyContinue
Stop-Service ServerManagementGateway -Force -ErrorAction SilentlyContinue

$RutaCache1 = "$env:ProgramData\Microsoft\Windows\ServerManagementGateway\Cache"
$RutaCache2 = "$env:ProgramData\ServerManagementGateway\Cache"

if (Test-Path $RutaCache1) { Remove-Item "$RutaCache1\*" -Recurse -Force; Write-Host "Caché 1 borrada." }
if (Test-Path $RutaCache2) { Remove-Item "$RutaCache2\*" -Recurse -Force; Write-Host "Caché 2 borrada." }

Write-Host "Iniciando servicio..." -ForegroundColor Green
Start-Service WindowsAdminCenter -ErrorAction SilentlyContinue
Start-Service ServerManagementGateway -ErrorAction SilentlyContinue

#-------------------------------------------------------
# Comprobación
#-------------------------------------------------------
chromium https://msasorcorg
chromium https://192.168.25.12/servermanager/connections/server/msasorcorg/tools/services/name/FDResPub

# Iniciar sesión
# Autoagregar servidor 192.168.25.12