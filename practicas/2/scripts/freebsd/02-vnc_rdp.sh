#!/bin/bash

# --- Configuración de VNC ---
# Establece la contraseña de VNC (12345678)
echo -e '12345678
12345678
n
' | vncpasswd

# !!! AQUí AQUí, SE QUE ME ESTáS BUSCANDO, por si te has olvidado !!!
# Inicia el servidor VNC en el display :1
# Detener servicio vnc en display :1 y arrancarlo
vncserver -kill :1
vncserver -localhost no -geometry 800x600 -xstartup /usr/local/bin/startxfce4 :1

# Validar servicio VNC
sockstat | grep vnc
sockstat | grep 5901

# --- Configuración de RDP ---
# Descomentar la línea 238 ===> delay_ms=2000
nano /usr/local/etc/xrdp/xrdp.ini

# Crear script de inicio y otorgar permisos
echo '#!/bin/sh
exec startxfce4' > ~/startwm.sh
chmod 777 ~/startwm.sh

# Validar servicio XRDP
sockstat | grep xrdp
sockstat | grep 3389
