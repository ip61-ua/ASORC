#!/bin/sh
su -

#-------------------------------------------------------
# Variables de entorno
#-------------------------------------------------------
P3ASORC_SERVICIO=chat
P3ASORC_SISTEMA=unix

# Rutas de entrega (NO TOCAR)
P3ASORC_MEMORIA=/home/ivan/SUPERMEMORIA/$P3ASORC_SERVICIO
P3ASORC_CONFIG=$P3ASORC_MEMORIA/ficheros_configuracion
P3ASORC_LOG=$P3ASORC_MEMORIA/$P3ASORC_SISTEMA.log
P3ASORC_HISTORIAL=$P3ASORC_MEMORIA/history$P3ASORC_SISTEMA.txt

# --- Variables específicas del servicio ---
P3ASORC_CHAT_DOMAIN=$(hostname)
P3ASORC_CHAT_USER1=usuario_chat1
P3ASORC_CHAT_USER2=usuario_chat2
P3ASORC_CHAT_PASS=1

# Rutas de configuración y logs de ejabberd
P3ASORC_CHAT_CONFIG_FILE=/usr/local/etc/ejabberd/ejabberd.yml
P3ASORC_CHAT_LOG_DIR=/var/log/ejabberd
P3ASORC_CHAT_LOG_FILE=$P3ASORC_CHAT_LOG_DIR/ejabberd.log

#-------------------------------------------------------
# Servicio
#-------------------------------------------------------
# PASO 1: Limpieza y paquetes
# Borrar logs anteriores
service ejabberd stop
pkill -9 beam
pkill -9 epmd
pkill -9 ejabberd
rm -rf $P3ASORC_CHAT_LOG_FILE
rm -rf /var/spool/ejabberd

# Instalación limpia
pkg remove -y ejabberd
pkg install -y ejabberd

# Fichero de configuración
cat << EOF > $P3ASORC_CHAT_CONFIG_FILE
loglevel: 5
log_rotate_count: 0
hosts:
  - "$P3ASORC_CHAT_DOMAIN"
  - "localhost"

certfiles:
  - "/usr/local/etc/ejabberd/ejabberd.pem"

listen:
  -
    port: 5222
    ip: "0.0.0.0"
    module: ejabberd_c2s
    max_stanza_size: 262144
    shaper: c2s_shaper
    access: c2s
    starttls_required: true
  -
    port: 5223
    ip: "::"
    module: ejabberd_c2s
    max_stanza_size: 262144
    shaper: c2s_shaper
    access: c2s
    tls: true
  -
    port: 5269
    ip: "::"
    module: ejabberd_s2s_in
    max_stanza_size: 524288
    shaper: s2s_shaper
  -
    port: 5443
    ip: "::"
    module: ejabberd_http
    tls: true
    request_handlers:
      /admin: ejabberd_web_admin
      /api: mod_http_api
      /bosh: mod_bosh
      /captcha: ejabberd_captcha
      /upload: mod_http_upload
      /ws: ejabberd_http_ws
  -
    port: 5280
    ip: "::"
    module: ejabberd_http
    request_handlers:
      /admin: ejabberd_web_admin
      /.well-known/acme-challenge: ejabberd_acme
  -
    port: 5478
    ip: "::"
    transport: udp
    module: ejabberd_stun
    use_turn: true
  -
    port: 1883
    ip: "::"
    module: mod_mqtt
    backlog: 1000

s2s_use_starttls: optional

acl:
  local:
    user_regexp: ""
  loopback:
    ip:
      - 127.0.0.0/8
      - ::1/128

access_rules:
  local:
    allow: local
  c2s:
    deny: blocked
    allow: all
  announce:
    allow: admin
  configure:
    allow: admin
  muc_create:
    allow: local
  pubsub_createnode:
    allow: local
  trusted_network:
    allow: loopback

api_permissions:
  "console commands":
    from: ejabberd_ctl
    who: all
    what: "*"
  "webadmin commands":
    from: ejabberd_web_admin
    who: admin
    what: "*"
  "adhoc commands":
    from: mod_adhoc_api
    who: admin
    what: "*"
  "http access":
    from: mod_http_api
    who:
      access:
        allow:
          - acl: loopback
          - acl: admin
      oauth:
        scope: "ejabberd:admin"
        access:
          allow:
            - acl: loopback
            - acl: admin
    what:
      - "*"
      - "!stop"
      - "!start"
  "public commands":
    who:
      ip: 127.0.0.1/8
    what:
      - status
      - connected_users_number

shaper:
  normal:
    rate: 3000
    burst_size: 20000
  fast: 100000

shaper_rules:
  max_user_sessions: 10
  max_user_offline_messages:
    5000: admin
    100: all
  c2s_shaper:
    none: admin
    normal: all
  s2s_shaper: fast

modules:
  mod_adhoc: {}
  mod_adhoc_api: {}
  mod_admin_extra: {}
  mod_announce:
    access: announce
  mod_avatar: {}
  mod_blocking: {}
  mod_bosh: {}
  mod_caps: {}
  mod_carboncopy: {}
  mod_client_state: {}
  mod_configure: {}
  mod_disco: {}
  mod_http_api: {}
  mod_http_upload:
    put_url: https://@HOST_URL_ENCODE@:5443/upload
    custom_headers:
      "Access-Control-Allow-Origin": "https://@HOST@"
      "Access-Control-Allow-Methods": "GET,HEAD,PUT,OPTIONS"
      "Access-Control-Allow-Headers": "Content-Type"
  mod_last: {}
  mod_mam:
    assume_mam_usage: true
    default: always
  mod_mqtt: {}
  mod_muc:
    access:
      - allow
    access_admin:
      - allow: admin
    access_create: muc_create
    access_persistent: muc_create
    access_mam:
      - allow
    default_room_options:
      mam: true
  mod_muc_admin: {}
  mod_muc_occupantid: {}
  mod_offline:
    access_max_user_messages: max_user_offline_messages
  mod_ping: {}
  mod_privacy: {}
  mod_private: {}
  mod_proxy65:
    access: local
    max_connections: 5
  mod_pubsub:
    access_createnode: pubsub_createnode
    plugins:
      - flat
      - pep
    force_node_config:
      storage:bookmarks:
        access_model: whitelist
  mod_push: {}
  mod_push_keepalive: {}
  mod_register:
    ip_access: trusted_network
  mod_roster:
    versioning: true
  mod_s2s_bidi: {}
  mod_s2s_dialback: {}
  mod_shared_roster: {}
  mod_stream_mgmt:
    resend_on_timeout: if_offline
  mod_stun_disco: {}
  mod_vcard: {}
  mod_vcard_xupdate: {}
  mod_version:
    show_os: false
EOF

# Claves (REQUIERE su atención)
cat << EOF | openssl req -new -x509 -days 365 -nodes -out /usr/local/etc/ejabberd/ejabberd.pem -keyout /usr/local/etc/ejabberd/ejabberd.pem
AU
Some-State
Alicante
Ministerio de la Hacienda
seccion
$P3ASORC_CHAT_DOMAIN
laligadelosvengadores@gmail.ru

EOF

# PASO 3: Permisos
chown ejabberd:ejabberd $P3ASORC_CHAT_CONFIG_FILE
chmod 640 $P3ASORC_CHAT_CONFIG_FILE
chown ejabberd:ejabberd /usr/local/etc/ejabberd/ejabberd.pem
chmod 600 /usr/local/etc/ejabberd/ejabberd.pem

# PASO 4: Aplicar cambios
sysrc ejabberd_enable="YES"
service ejabberd restart
sleep 20

# PASO 5: Sincronizar galletas
cp /var/spool/ejabberd/.erlang.cookie /root/.erlang.cookie
chmod 400 /root/.erlang.cookie

# PASO 6: Regisrar usuarios
EJABBERDCTL="/usr/local/sbin/ejabberdctl"
$EJABBERDCTL unregister $P3ASORC_CHAT_USER1 $P3ASORC_CHAT_DOMAIN
$EJABBERDCTL unregister $P3ASORC_CHAT_USER2 $P3ASORC_CHAT_DOMAIN
$EJABBERDCTL register $P3ASORC_CHAT_USER1 $P3ASORC_CHAT_DOMAIN $P3ASORC_CHAT_PASS
$EJABBERDCTL register $P3ASORC_CHAT_USER2 $P3ASORC_CHAT_DOMAIN $P3ASORC_CHAT_PASS

#-------------------------------------------------------
# Valida servicio
#-------------------------------------------------------
service ejabberd status
sockstat -4 -6 -l | grep beam
tail /var/log/ejabberd/ejabberd.log

#-------------------------------------------------------
# Extraer logs, configs e historial
#-------------------------------------------------------
rm -rf $P3ASORC_MEMORIA
mkdir -p $P3ASORC_MEMORIA
mkdir -p $P3ASORC_CONFIG

cp $P3ASORC_CHAT_CONFIG_FILE $P3ASORC_CONFIG
cp $P3ASORC_CHAT_LOG_FILE $P3ASORC_LOG

history > $P3ASORC_HISTORIAL
chmod 777 $P3ASORC_MEMORIA

tree $P3ASORC_MEMORIA

#-------------------------------------------------------
# Comprobación desde host
#-------------------------------------------------------
sudo dnf install -y pidgin

pidgin -m
