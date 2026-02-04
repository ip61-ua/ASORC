#!/bin/bash

# --- Configuración de VNC ---
# Instala: - dbus-x11 (necesario para XFCE),
#          - los paquetes de TigerVNC (servidor VNC)
#          - net-tools (para netstat)
apt install -y dbus-x11 tigervnc-* net-tools

# Establece la contraseña de VNC (12345678)
echo -e '12345678
12345678
n
' | vncpasswd

# Crea el script de arranque de VNC (~/start-vnc.sh) para usar xfce en vnc y dar permisos de ejecución
echo -e '#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
startxfce4' > ~/start-vnc.sh
chmod +x ~/start-vnc.sh

# Mapea el display :1 de VNC al usuario 'ivan'
echo -e ':1=ivan' > /etc/tigervnc/vncserver.users

# Inicia el servidor VNC en el display :1, sin localhost y con el script de arranque personalizado
vncserver -localhost no -geometry 800x600 -xstartup ~/start-vnc.sh :1

# Añade el usuario 'xrdp' al grupo 'ssl-cert' para permisos de certificados
adduser xrdp ssl-cert

# Validar servicio VNC
netstat -tunlp | grep vnc

# Detener servicio vnc en display :1
tigervncserver -kill :1

# --- Configuración de RDP ---
# Instala el servidor RDP (xrdp) y el backend Xorg (xorgxrdp) necesarios
apt install -y xrdp xorgxrdp

# Igual que VNC, crea el fichero ~/.xsession que xrdp usará para iniciar el escritorio
cat << 'EOF' > ~/.xsession
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec startxfce4
EOF
chmod +x ~/.xsession

# Sobrescribe el fichero de configuración del gestor de sesiones RDP habilitando el log en modo DEBUG
echo -e '
[Globals]
EnableUserWindowManager=true
UserWindowManager=startwm.sh
DefaultWindowManager=startwm.sh
ReconnectScript=reconnectwm.sh

[Security]
AllowRootLogin=true
MaxLoginRetry=4
TerminalServerUsers=tsusers
TerminalServerAdmins=tsadmins
AlwaysGroupCheck=false
RestrictOutboundClipboard=none
RestrictInboundClipboard=none

[Sessions]
X11DisplayOffset=10
MaxSessions=50
KillDisconnected=false
DisconnectedTimeLimit=0
IdleTimeLimit=0
Policy=Default

[Logging]
LogFile=xrdp-sesman.log
LogLevel=DEBUG
EnableSyslog=true
SyslogLevel=DEBUG

[LoggingPerLogger]
#sesman.c=INFO
#main()=INFO

[Xorg]
param=/usr/lib/xorg/Xorg
param=-config
param=xrdp/xorg.conf
param=-noreset
param=-nolisten
param=tcp
param=-logfile
param=.xorgxrdp.%s.log

[Xvnc]
param=Xvnc
param=-bs
param=-nolisten
param=tcp
param=-localhost
param=-dpi
param=96

[Chansrv]
FuseMountName=thinclient_drives
FileUmask=077

[ChansrvLogging]
LogLevel=INFO
EnableSyslog=true
SyslogLevel=DEBUG

[ChansrvLoggingPerLogger]
#chansrv.c=INFO
#main()=INFO

[SessionVariables]
PULSE_SCRIPT=/etc/xrdp/pulse/default.pa
' > /etc/xrdp/sesman.ini

# Reinicia el servicio RDP para aplicar los cambios
systemctl restart xrdp

# Validar servicio RDP
systemctl status xrpd
netstat -tunlp | grep xrdp
