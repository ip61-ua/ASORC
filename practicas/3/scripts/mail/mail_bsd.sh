#!/bin/sh
su -

#-------------------------------------------------------
# Variables de entorno
#-------------------------------------------------------
P3ASORC_SERVICIO=mail
P3ASORC_SISTEMA=unix

# NO TOCAR
P3ASORC_MEMORIA=/home/ivan/SUPERMEMORIA/$P3ASORC_SERVICIO
P3ASORC_CONFIG=$P3ASORC_MEMORIA/ficheros_configuracion
P3ASORC_LOG=$P3ASORC_MEMORIA/$P3ASORC_SISTEMA.log
P3ASORC_HISTORIAL=$P3ASORC_MEMORIA/history$P3ASORC_SISTEMA.txt
P3ASORC_BSD_RC=/etc/rc.conf

P3ASORC_MAIL_HOSTNAME=bsdasorc.org
P3ASORC_MAIL_MAIL_HOSTNAME=mail.$P3ASORC_MAIL_HOSTNAME
P3ASORC_MAIL_OSUSER=mailusuario1
P3ASORC_MAIL_OSUSER_PASS=1
P3ASORC_MAIL_OSUSER1=mailusuario2
P3ASORC_MAIL_OSUSER1_PASS=1
P3ASORC_MAIL_CUBO=/usr/local/www/roundcube
P3ASORC_MAIL_MIMARCA="BSDmail"
P3ASORC_MAIL_DB_SQLITE_DST_ROOT=/var/db/roundcube
P3ASORC_MAIL_DB_SQLITE_DST=$P3ASORC_MAIL_DB_SQLITE_DST_ROOT/cuboredondo.db
P3ASORC_MAIL_CUBOLOG_DST_COMMON=/var/log/roundcube-ui
P3ASORC_MAIL_CLE=$P3ASORC_MAIL_CUBOLOG_DST_COMMON-error.log
P3ASORC_MAIL_CLA=$P3ASORC_MAIL_CUBOLOG_DST_COMMON-access.log
P3ASORC_MAIL_SQL_BIN=/usr/local/bin/sqlite3
P3ASORC_MAIL_CONFIG=/etc/mail/mailer.conf
P3ASORC_MAIL_CONFIG1=/usr/local/etc/postfix/main.cf
P3ASORC_MAIL_CONFIG2=/usr/local/etc/dovecot/dovecot.conf
P3ASORC_MAIL_CONFIG3=/usr/local/etc/dovecot/conf.d/10-mail.conf
P3ASORC_MAIL_CONFIG4=/usr/local/etc/dovecot/conf.d/10-auth.conf
P3ASORC_MAIL_CONFIG5=$P3ASORC_MAIL_CUBO/config/config.inc.php
P3ASORC_MAIL_CONFIG6=/usr/local/etc/apache24/Includes/roundcube.conf
P3ASORC_MAIL_CONFIG7=/usr/local/etc/dovecot/conf.d/10-ssl.conf
P3ASORC_MAIL_CONFIG8=/usr/local/etc/php.ini
P3ASORC_MAIL_AMAVIS_CONF="/usr/local/etc/amavisd.conf"
P3ASORC_MAIL_MASTER_CF="/usr/local/etc/postfix/master.cf"
P3ASORC_MAIL_CLAMD_CONF="/usr/local/etc/clamd.conf"
P3ASORC_MAIL_FRESHCLAM_CONF="/usr/local/etc/freshclam.conf"
P3ASORC_MAIL_HOSTS=/etc/hosts
P3ASORC_MAIL_NALIASBIN=/usr/local/bin/newaliases
P3ASORC_MAIL_NALIASDB=/etc/aliases.db
P3ASORC_MAIL_HOSTINGS_ETC="localhost localhost.my.domain nextbsd.org dbbsd.org web1bsd.org web2bsd.org bsd.bsd.asorc.org bsd.asorc.org"
P3ASORC_MAIL_CONFIG_PORT_FILTER1=10024
P3ASORC_MAIL_CONFIG_PORT_FILTER2=10025

#-------------------------------------------------------
# Servicio (no backtrack)
#-------------------------------------------------------
# PASO 0: Instalar paquetería
pkg install -y postfix dovecot roundcube-php83 amavisd-new clamav spamassassin mod_php83 php83-pdo_sqlite php83-filter php83-mbstring php83-iconv php83-session php83-ctype php83-dom php83-xml php83-simplexml php83-sqlite3 php83-intl php83-zip

# PASO 1: Configurar hosts
cat << EOF > $P3ASORC_MAIL_HOSTS
::1             $P3ASORC_MAIL_HOSTINGS_ETC
127.0.0.1       $P3ASORC_MAIL_HOSTINGS_ETC
192.168.25.11   $P3ASORC_MAIL_HOSTINGS_ETC
EOF

$P3ASORC_MAIL_NALIASBIN
chmod 644 $P3ASORC_MAIL_NALIASDB

# PASO 2: Inicializar postfix
cat << EOF > $P3ASORC_MAIL_CONFIG
#
# mailer.conf for use with dma(8)
#
# If sendmail is configured, an example of mailer.conf that uses sendmail
# instead can be found in /usr/share/examples/sendmail.

sendmail        /usr/local/sbin/postfix
send-mail       /usr/local/sbin/postfix
mailq           /usr/local/sbin/postfix
newaliases      /usr/local/sbin/postfix
EOF

sysrc sendmail_enable="NO"
sysrc sendmail_submit_enable="NO"
sysrc sendmail_outbound_enable="NO"
sysrc sendmail_msp_queue_enable="NO"
sysrc postfix_enable="YES"

# PASO 3: Configurar postfix
cat << EOF > $P3ASORC_MAIL_CONFIG1
compatibility_level = 3.10
#soft_bounce = no
queue_directory = /var/spool/postfix
command_directory = /usr/local/sbin
daemon_directory = /usr/local/libexec/postfix
data_directory = /var/db/postfix
mail_owner = postfix
#default_privs = nobody
myhostname = $P3ASORC_MAIL_MAIL_HOSTNAME
#myhostname = virtual.domain.tld
#mydomain = domain.tld
mydomain = $P3ASORC_MAIL_HOSTNAME
#myorigin = \$myhostname
myorigin = \$mydomain
inet_interfaces = all
#inet_interfaces = \$myhostname
#inet_interfaces = \$myhostname, localhost
#proxy_interfaces =
#proxy_interfaces = 1.2.3.4
mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain
#mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain
#mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain,
#local_recipient_maps = unix:passwd.byname \$alias_maps
#local_recipient_maps = proxy:unix:passwd.byname \$alias_maps
#local_recipient_maps =
unknown_local_recipient_reject_code = 550
#mynetworks_style = class
#mynetworks_style = subnet
mynetworks_style = host
#mynetworks = 168.100.3.0/28, 127.0.0.0/8
#mynetworks = \$config_directory/mynetworks
#mynetworks = hash:\$config_directory/network_table
#relay_domains =
relay_domains = \$mydestination
#relayhost = \$mydomain
#relayhost = [gateway.my.domain]
#relayhost = [mailserver.isp.tld]
#relayhost = uucphost
#relayhost = [an.ip.add.ress]
#relay_recipient_maps = hash:\$config_directory/relay_recipients
#in_flow_delay = 1s
#alias_maps = dbm:/etc/aliases
#alias_maps = hash:/etc/aliases
#alias_maps = hash:/etc/aliases, nis:mail.aliases
#alias_maps = netinfo:/aliases
#alias_database = dbm:/etc/aliases
#alias_database = hash:/etc/aliases
#alias_database = hash:/etc/aliases, hash:/opt/majordomo/aliases
#recipient_delimiter = +
#home_mailbox = Mailbox
home_mailbox = Maildir/
#mail_spool_directory = /var/mail
#mail_spool_directory = /var/spool/mail
#mailbox_command = /some/where/procmail
#mailbox_command = /some/where/procmail -a "\$EXTENSION"
#mailbox_transport = lmtp:unix:/var/imap/socket/lmtp
#mailbox_transport = cyrus
#fallback_transport = lmtp:unix:/file/name
#fallback_transport = cyrus
#fallback_transport =
#luser_relay = \$user@other.host
#luser_relay = \$local@other.host
#luser_relay = admin+\$local
#header_checks = regexp:\$config_directory/header_checks
#fast_flush_domains = \$relay_domains
smtpd_banner = \$myhostname ESMTP \$mail_name
#smtpd_banner = \$myhostname ESMTP \$mail_name (\$mail_version)
#local_destination_concurrency_limit = 2
#default_destination_concurrency_limit = 20
debug_peer_level = 2
#debug_peer_list = 127.0.0.1
#debug_peer_list = some.domain
debugger_command =
         PATH=/bin:/usr/bin:/usr/local/bin:/usr/X11R6/bin
         ddd \$daemon_directory/\$process_name \$process_id & sleep 5
sendmail_path = /usr/local/sbin/sendmail
newaliases_path = /usr/local/bin/newaliases
mailq_path = /usr/local/bin/mailq
setgid_group = maildrop
html_directory = /usr/local/share/doc/postfix
manpage_directory = /usr/local/share/man
sample_directory = /usr/local/etc/postfix
readme_directory = /usr/local/share/doc/postfix
inet_protocols = ipv4
smtp_tls_CApath = /etc/ssl/certs
meta_directory = /usr/local/libexec/postfix
shlib_directory = /usr/local/lib/postfix
smtpd_use_tls = no
smtpd_tls_security_level = none
smtp_tls_security_level = none
smtp_dns_support_level = disabled
content_filter = smtp-amavis:[127.0.0.1]:$P3ASORC_MAIL_CONFIG_PORT_FILTER1
EOF

echo "ssl = no" > $P3ASORC_MAIL_CONFIG7

service postfix enable
service postfix start

postconf -e "disable_dns_lookups = yes"
service postfix restart

# PASO 4: Configurar devocot
sysrc dovecot_enable="YES"
cat << EOF > $P3ASORC_MAIL_CONFIG2
protocols = imap
listen = *
#base_dir = /var/run/dovecot/
#instance_name = dovecot
#login_greeting = Dovecot ready.
#login_trusted_networks =
#login_access_sockets =
#auth_proxy_self =
#verbose_proctitle = no
#shutdown_clients = yes
#doveadm_worker_count = 0
#doveadm_socket_path = doveadm-server
#import_environment = TZ
dict {
  #quota = mysql:/usr/local/etc/dovecot/dovecot-dict-sql.conf.ext
}
!include conf.d/*.conf
!include_try local.conf
EOF

# PASO 5: Configurar buzones
cat << EOF > $P3ASORC_MAIL_CONFIG3
mail_location = maildir:~/Maildir
namespace inbox {
  #type = private
  #separator =
  #prefix =
  #location =
  inbox = yes
  #hidden = no
  #list = yes
  #subscriptions = yes
}

#namespace {
  #type = shared
  #separator = /
  #prefix = shared/%%u/
  #location = maildir:%%h/Maildir:INDEX=~/Maildir/shared/%%u
  #subscriptions = no
  #list = children
#}
#mail_shared_explicit_inbox = no
#mail_uid =
#mail_gid =
#mail_privileged_group =
#mail_access_groups =
#mail_full_filesystem_access = no
#mail_attribute_dict =
#mail_server_comment = ""
#mail_server_admin =
#mmap_disable = no
#dotlock_use_excl = yes
#mail_fsync = optimized
#lock_method = fcntl
#mail_temp_dir = /tmp
#first_valid_uid = 500
#last_valid_uid = 0
#first_valid_gid = 1
#last_valid_gid = 0
#mail_max_keyword_length = 50
#valid_chroot_dirs =
#mail_chroot =
#auth_socket_path = /var/run/dovecot/auth-userdb
#mail_plugin_dir = /usr/lib/dovecot
#mail_plugins =
#mailbox_list_index = yes
#mailbox_list_index_very_dirty_syncs = yes
#mailbox_list_index_include_inbox = no
#mail_cache_min_mail_count = 0
#mailbox_idle_check_interval = 30 secs
#mail_save_crlf = no
#mail_prefetch_count = 0
#mail_temp_scan_interval = 1w
#mail_sort_max_read_count = 0
protocol !indexer-worker {
  #mail_vsize_bg_after_count = 0
}
#maildir_stat_dirs = no
#maildir_copy_with_hardlinks = yes
#maildir_very_dirty_syncs = no
#maildir_broken_filename_sizes = no
#maildir_empty_new = no
#mbox_read_locks = fcntl
#mbox_write_locks = dotlock fcntl
#mbox_lock_timeout = 5 mins
#mbox_dotlock_change_timeout = 2 mins
#mbox_dirty_syncs = yes
#mbox_very_dirty_syncs = no
#mbox_lazy_writes = yes
#mbox_min_index_size = 0
#mbox_md5 = apop3d
#mdbox_rotate_size = 10M
#mdbox_rotate_interval = 0
#mdbox_preallocate_space = no
#mail_attachment_dir =
#mail_attachment_min_size = 128k
#mail_attachment_fs = sis posix
#mail_attachment_hash = %{sha1}
#mail_attachment_detection_options =
EOF

# PASO 5: Configurar autenticación
cat << EOF > $P3ASORC_MAIL_CONFIG4
disable_plaintext_auth = no
#auth_cache_size = 0
#auth_cache_ttl = 1 hour
#auth_cache_negative_ttl = 1 hour
#auth_realms =
#auth_default_realm =
#auth_username_chars = abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890.-_@
#auth_username_translation =
#auth_username_format = %Lu
#auth_master_user_separator =
#auth_anonymous_username = anonymous
#auth_worker_max_count = 30
#auth_gssapi_hostname =
#auth_krb5_keytab =
#auth_use_winbind = no
#auth_winbind_helper_path = /usr/bin/ntlm_auth
#auth_failure_delay = 2 secs
#auth_ssl_require_client_cert = no
#auth_ssl_username_from_cert = no
auth_mechanisms = plain login

#!include auth-deny.conf.ext
#!include auth-master.conf.ext

!include auth-system.conf.ext
#!include auth-sql.conf.ext
#!include auth-ldap.conf.ext
#!include auth-passwdfile.conf.ext
#!include auth-checkpassword.conf.ext
#!include auth-static.conf.ext
EOF

service dovecot start
service dovecot restart

# PASO 6: Añadir usuarios
pw userdel -n $P3ASORC_MAIL_OSUSER -y 2>/dev/null
pw userdel -n $P3ASORC_MAIL_OSUSER1 -y 2>/dev/null

echo "$P3ASORC_MAIL_OSUSER_PASS" | pw useradd -n $P3ASORC_MAIL_OSUSER -s /sbin/nologin -m -h 0
echo "$P3ASORC_MAIL_OSUSER1_PASS" | pw useradd -n $P3ASORC_MAIL_OSUSER1 -s /sbin/nologin -m -h 0

mkdir -p /home/$P3ASORC_MAIL_OSUSER/Maildir/{cur,new,tmp}
mkdir -p /home/$P3ASORC_MAIL_OSUSER1/Maildir/{cur,new,tmp}

chown -R $P3ASORC_MAIL_OSUSER:$P3ASORC_MAIL_OSUSER /home/$P3ASORC_MAIL_OSUSER/Maildir
chown -R $P3ASORC_MAIL_OSUSER1:$P3ASORC_MAIL_OSUSER1 /home/$P3ASORC_MAIL_OSUSER1/Maildir
chmod -R 700 /home/$P3ASORC_MAIL_OSUSER/Maildir
chmod -R 700 /home/$P3ASORC_MAIL_OSUSER1/Maildir

# PASO 7: Inicializar base de datos para frontend
rm -f $P3ASORC_MAIL_DB_SQLITE_DST
rm -rf $P3ASORC_MAIL_DB_SQLITE_DST_ROOT
mkdir -p $P3ASORC_MAIL_DB_SQLITE_DST_ROOT
chown www:www $P3ASORC_MAIL_DB_SQLITE_DST_ROOT

cp /usr/local/etc/php.ini-production "$P3ASORC_MAIL_CONFIG8"
sed -i .bak 's|^;* *session.save_path =.*|session.save_path = "/tmp"|' "$P3ASORC_MAIL_CONFIG8"
sed -i .bak 's/^extension=/;extension=/' "$P3ASORC_MAIL_CONFIG8"

$P3ASORC_MAIL_SQL_BIN $P3ASORC_MAIL_DB_SQLITE_DST < $P3ASORC_MAIL_CUBO/SQL/sqlite.initial.sql
chown www:www $P3ASORC_MAIL_DB_SQLITE_DST
chown www:www $P3ASORC_MAIL_DB_SQLITE_DST_ROOT
chmod 775 $P3ASORC_MAIL_DB_SQLITE_DST_ROOT
chmod 664 $P3ASORC_MAIL_DB_SQLITE_DST
chown -R www:www $P3ASORC_MAIL_CUBO/logs $P3ASORC_MAIL_CUBO/temp
chown -R 775 $P3ASORC_MAIL_CUBO/logs
chown -R 775 $P3ASORC_MAIL_CUBO/temp

# PASO 8: Habilitar frontend web
chown -R www:www $P3ASORC_MAIL_CUBO/
cat << EOF > $P3ASORC_MAIL_CONFIG5
<?php
\$config = [];
\$config['db_dsnw'] = 'sqlite:////$P3ASORC_MAIL_DB_SQLITE_DST?mode=0646';
\$config['imap_host'] = 'localhost:143';
\$config['smtp_host'] = 'localhost:25';
\$config['smtp_user'] = '';
\$config['smtp_pass'] = '';
\$config['support_url'] = '';
\$config['product_name'] = '$P3ASORC_MAIL_MIMARCA';
\$config['des_key'] = 'rcmail-!24ByteDESkey*Str';
\$config['plugins'] = [
    'archive',
    'zipdownload',
];
\$config['skin'] = 'elastic';
EOF

cat << EOF > $P3ASORC_MAIL_CONFIG6
Alias /roundcube "$P3ASORC_MAIL_CUBO"

ErrorLog $P3ASORC_MAIL_CLE
CustomLog $P3ASORC_MAIL_CLA combined

<Directory $P3ASORC_MAIL_CUBO>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
    DirectoryIndex index.php
</Directory>
EOF

service apache24 restart

# PASO 9: Antivirus + SPAM
sysrc clamav_clamd_enable="YES"
sysrc clamav_freshclam_enable="YES"
sysrc amavisd_enable="YES"
sysrc spamd_enable="YES"

cp /usr/local/etc/freshclam.conf.sample $P3ASORC_MAIL_FRESHCLAM_CONF
cp /usr/local/etc/clamd.conf.sample $P3ASORC_MAIL_CLAMD_CONF
sed -i .bak 's/^Example/#Example/' $P3ASORC_MAIL_FRESHCLAM_CONF
sed -i .bak 's/^Example/#Example/' $P3ASORC_MAIL_CLAMD_CONF
sed -i .bak 's|^#LocalSocket .*|LocalSocket /var/run/clamav/clamd.sock|' $P3ASORC_MAIL_CLAMD_CONF

mkdir -p /var/run/clamav
chown clamav:clamav /var/run/clamav

freshclam
sa-update

sed -i .bak 's/^#@bypass_virus_checks_maps/@bypass_virus_checks_maps/' $P3ASORC_MAIL_AMAVIS_CONF
sed -i .bak 's/^#@bypass_spam_checks_maps/@bypass_spam_checks_maps/' $P3ASORC_MAIL_AMAVIS_CONF
pw groupmod vscan -m clamav

cat << EOF >> $P3ASORC_MAIL_MASTER_CF

smtp-amavis unix -      -       n       -       2 smtp
    -o smtp_data_done_timeout=1200
    -o smtp_send_xforward_command=yes
    -o smtp_dns_support_level=disabled

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

# PASO 10: Reinicio de la pila de correo
service sa-spamd start
service clamav_freshclam start
service clamav_clamd restart
service amavisd restart
service postfix restart

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
cp $P3ASORC_MAIL_AMAVIS_CONF $P3ASORC_CONFIG
cp $P3ASORC_MAIL_MASTER_CF $P3ASORC_CONFIG
cp $P3ASORC_MAIL_CLAMD_CONF $P3ASORC_CONFIG
cp $P3ASORC_MAIL_FRESHCLAM_CONF $P3ASORC_CONFIG

{
    echo "=========================================================="
    echo " ESTADO DE SERVICIOS"
    echo "=========================================================="
    service postfix status
    service dovecot status
    service apache24 status
    service amavisd status
    service clamav_clamd status
    service clamav_freshclam status
    service sa-spamd status

    echo ""
    echo "=========================================================="
    echo " PUERTOS ESCUCHANDO (sockstat)"
    echo "=========================================================="
    # Verificamos puertos críticos: 25(smtp), 143(imap), 10024(amavis), 10025(postfix-reentry), 3310(clamav), 783(spamassassin)
    sockstat -4 -l | grep -E '25|143|10024|10025|3310|783'

    echo ""
    echo "=========================================================="
    echo " /var/log/maillog"
    echo "=========================================================="
    tail -n 999 /var/log/maillog

    echo ""
    echo "=========================================================="
    echo " ERRORES DE ROUNDCUBE"
    echo "=========================================================="
    tail -n 999 "$P3ASORC_MAIL_CLE"
    tail -n 999 "$P3ASORC_MAIL_CLA"
} > $P3ASORC_LOG

history > $P3ASORC_HISTORIAL
chmod 777 -R $P3ASORC_MEMORIA

tree $P3ASORC_MEMORIA

#-------------------------------------------------------
# Comprobacion desde host
#-------------------------------------------------------
# http://192.168.25.11/roundcube P3ASORC_MAIL_OSUSER P3ASORC_MAIL_OSUSER_PASS
# P3ASORC_MAIL_OSUSER -> P3ASORC_MAIL_OSUSER1@P3ASORC_MAIL_HOSTNAME
# http://192.168.25.11/roundcube P3ASORC_MAIL_OSUSER1 P3ASORC_MAIL_OSUSER_PASS1
# P3ASORC_MAIL_OSUSER1 -> P3ASORC_MAIL_OSUSER@P3ASORC_MAIL_HOSTNAME
# VER LOS METADATOS DEL CORREO en busca X-Virus, spam...
# Mostrar fichero P3ASORC_MAIL_AMAVIS_CONF