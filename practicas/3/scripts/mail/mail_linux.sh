#!/bin/sh
su -

#-------------------------------------------------------
# Variables de entorno
#-------------------------------------------------------
P3ASORC_SERVICIO=mail
P3ASORC_SISTEMA=linux

# NO TOCAR
P3ASORC_MEMORIA=/home/ivan/SUPERMEMORIA/$P3ASORC_SERVICIO
P3ASORC_CONFIG=$P3ASORC_MEMORIA/ficheros_configuracion
P3ASORC_LOG=$P3ASORC_MEMORIA/$P3ASORC_SISTEMA.log
P3ASORC_HISTORIAL=$P3ASORC_MEMORIA/history$P3ASORC_SISTEMA.txt

P3ASORC_MAIL_HOSTNAME=debianasorc.org
P3ASORC_MAIL_MAIL_HOSTNAME=mail.$P3ASORC_MAIL_HOSTNAME
P3ASORC_MAIL_OSUSER=mailusuario1
P3ASORC_MAIL_OSUSER_PASS=1
P3ASORC_MAIL_OSUSER1=mailusuario2
P3ASORC_MAIL_OSUSER1_PASS=1
P3ASORC_MAIL_CONFIG=/etc/postfix/main.cf
P3ASORC_MAIL_CONFIG2=/etc/dovecot/dovecot.conf
P3ASORC_MAIL_CONFIG3=/etc/dovecot/conf.d/10-auth.conf
P3ASORC_MAIL_CONFIG4=/etc/dovecot/conf.d/10-mail.conf
P3ASORC_MAIL_CONFIG5=/etc/dovecot/conf.d/10-master.conf
P3ASORC_MAIL_CONFIG6=/etc/profile.d/mail.sh
P3ASORC_MAIL_CONFIG7=/etc/roundcube/config.inc.php
P3ASORC_MAIL_CONFIG8=/etc/apache2/conf-enabled/roundcube.conf
P3ASORC_MAIL_CONFIG9=/etc/mailname
P3ASORC_MAIL_CONFIG10=/etc/amavis/conf.d/15-content_filter_mode
P3ASORC_MAIL_CONFIG11=/etc/postfix/master.cf
P3ASORC_MAIL_CONFIG_PORT_MAIL=25
P3ASORC_MAIL_CONFIG_PORT_FILTER1=10024
P3ASORC_MAIL_CONFIG_PORT_FILTER2=10025

#-------------------------------------------------------
# Servicio
#-------------------------------------------------------
# PASO 0: Limpieza
apt purge -y postfix dovecot* roundcube* clamav* amavis* spamassassin* spamd
rm -rf /var/lib/roundcube /var/lib/dovecot /etc/dovecot

# PASO 1: Paquetería
apt update
apt install -y postfix clamav-daemon spamassassin amavisd-new dovecot-imapd roundcube-core mailutils dovecot-core roundcube clamav roundcube-sqlite3 nagios4* spamd

EEEEEEEEEEE=$DEBIAN_FRONTEND
export DEBIAN_FRONTEND=noninteractive
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
echo "postfix postfix/mailname string $P3ASORC_MAIL_MAIL_HOSTNAME" | debconf-set-selections
echo "roundcube-core roundcube/dbconfig-install boolean true" | debconf-set-selections
echo "roundcube-core roundcube/database-type select sqlite3" | debconf-set-selections
export DEBIAN_FRONTEND=$EEEEEEEEEEE

systemctl enable spamd
systemctl start spamd
systemctl enable clamav-freshclam
systemctl start clamav-freshclam

# PASO 2: Configurar IMAP de formas muy místicas
sed -i "s/^myhostname =.*/myhostname = $P3ASORC_MAIL_MAIL_HOSTNAME/" $P3ASORC_MAIL_CONFIG

if grep -q "^mydomain =" $P3ASORC_MAIL_CONFIG; then
    sed -i "s/^mydomain =.*/mydomain = $P3ASORC_MAIL_HOSTNAME/" $P3ASORC_MAIL_CONFIG
else
    echo "mydomain = $P3ASORC_MAIL_HOSTNAME" >> $P3ASORC_MAIL_CONFIG
fi

sed -i "s/^#*home_mailbox =.*/home_mailbox = Maildir\//" $P3ASORC_MAIL_CONFIG
sed -i "s/^mydestination =.*/mydestination = \$myhostname, \$mydomain, localhost.\$myhostname, localhost.\$mydomain, localhost/" $P3ASORC_MAIL_CONFIG
echo "$P3ASORC_MAIL_MAIL_HOSTNAME" > $P3ASORC_MAIL_CONFIG9
systemctl restart postfix

# PASO 3: Corresponder buzón
sed -i 's|^#*mail_location =.*|mail_location = maildir:~/Maildir|' $P3ASORC_MAIL_CONFIG4
if grep -q "^#*protocols =" $P3ASORC_MAIL_CONFIG2; then
    sed -i 's/^#*protocols =.*/protocols = imap/' $P3ASORC_MAIL_CONFIG2
else
    echo "protocols = imap" >> $P3ASORC_MAIL_CONFIG2
fi

# PASO 4: Autenticación
systemctl restart dovecot
sed -i 's|^#Alias /roundcube|Alias /roundcube|' $P3ASORC_MAIL_CONFIG8
sed -i "s/\\\$config\['smtp_host'\].*/\\\$config['smtp_host'] = 'localhost:25';/" $P3ASORC_MAIL_CONFIG7
sed -i "s/\\\$config\['smtp_user'\].*/\\\$config['smtp_user'] = '';/" $P3ASORC_MAIL_CONFIG7
sed -i "s/\\\$config\['smtp_pass'\].*/\\\$config['smtp_pass'] = '';/" $P3ASORC_MAIL_CONFIG7
systemctl restart apache2

# PASO 5: Permisos y usuarios
crear_usuario() {
    local USER=$1
    local PASS=$2
    userdel -r $USER 2>/dev/null
    adduser --disabled-password --gecos "" $USER
    echo "$USER:$PASS" | chpasswd
    mkdir -p /home/$USER/Maildir/{cur,new,tmp}
    chown -R $USER:$USER /home/$USER/Maildir/
    echo "Usuario $USER creado correctamente."
}

crear_usuario "$P3ASORC_MAIL_OSUSER" "$P3ASORC_MAIL_OSUSER_PASS"
crear_usuario "$P3ASORC_MAIL_OSUSER1" "$P3ASORC_MAIL_OSUSER1_PASS"

# PASO 6: Antivirus + SPAM
cat << 'EOF' > $P3ASORC_MAIL_CONFIG10
use strict;

@bypass_virus_checks_maps = (
   \%bypass_virus_checks, \@bypass_virus_checks_acl, \$bypass_virus_checks_re);

@bypass_spam_checks_maps = (
   \%bypass_spam_checks, \@bypass_spam_checks_acl, \$bypass_spam_checks_re);

1;
EOF

postconf -e "content_filter = smtp-amavis:[127.0.0.1]:$P3ASORC_MAIL_CONFIG_PORT_FILTER1"
cat << EOF >> $P3ASORC_MAIL_CONFIG11

smtp-amavis unix -      -       n       -       2 smtp
    -o smtp_data_done_timeout=1200
    -o smtp_send_xforward_command=yes
    -o disable_dns_lookups=yes

127.0.0.1:$P3ASORC_MAIL_CONFIG_PORT_FILTER2 inet n  -       n       -       - smtpd
    -o content_filter=
    -o local_recipient_maps=
    -o relay_recipient_maps=
    -o smtpd_restriction_classes=
    -o smtpd_client_restrictions=
    -o smtpd_helo_restrictions=
    -o smtpd_sender_restrictions=
    -o smtpd_recipient_restrictions=permit_mynetworks,reject
    -o mynetworks=127.0.0.0/8
    -o strict_rfc821_envelopes=yes
    -o smtpd_error_sleep_time=0
    -o smtpd_soft_error_limit=1001
    -o smtpd_hard_error_limit=1000
    -o receive_override_options=no_milters
EOF

usermod -aG amavis clamav
systemctl restart clamav-daemon amavis postfix

#-------------------------------------------------------
# Extraer logs, configs e historial
#-------------------------------------------------------
rm -rf $P3ASORC_MEMORIA
mkdir -p $P3ASORC_MEMORIA
mkdir -p $P3ASORC_CONFIG

cp $P3ASORC_MAIL_CONFIG $P3ASORC_CONFIG
cp $P3ASORC_MAIL_CONFIG2 $P3ASORC_CONFIG
cp $P3ASORC_MAIL_CONFIG3 $P3ASORC_CONFIG
cp $P3ASORC_MAIL_CONFIG4 $P3ASORC_CONFIG
cp $P3ASORC_MAIL_CONFIG5 $P3ASORC_CONFIG
cp $P3ASORC_MAIL_CONFIG6 $P3ASORC_CONFIG
cp $P3ASORC_MAIL_CONFIG7 $P3ASORC_CONFIG
cp $P3ASORC_MAIL_CONFIG8 $P3ASORC_CONFIG
cp $P3ASORC_MAIL_CONFIG9 $P3ASORC_CONFIG
systemctl status spamd amavis clamav-* postfix dovecot --no-pager -l > $P3ASORC_LOG

history > $P3ASORC_HISTORIAL
chmod 777 -R $P3ASORC_MEMORIA

tree $P3ASORC_MEMORIA

#-------------------------------------------------------
# Comprobacion desde host
#-------------------------------------------------------
# http://192.168.25.10/roundcube P3ASORC_MAIL_OSUSER P3ASORC_MAIL_OSUSER_PASS
# P3ASORC_MAIL_OSUSER -> P3ASORC_MAIL_OSUSER1@P3ASORC_MAIL_HOSTNAME
# http://192.168.25.10/roundcube P3ASORC_MAIL_OSUSER1 P3ASORC_MAIL_OSUSER_PASS1
# P3ASORC_MAIL_OSUSER1 -> P3ASORC_MAIL_OSUSER@P3ASORC_MAIL_HOSTNAME
# VER LOS METADATOS DEL CORREO en busca X-Virus, spam...
# Mostrar fichero P3ASORC_MAIL_CONFIG10