#!/bin/sh
su -

#-------------------------------------------------------
# Variables de entorno
#-------------------------------------------------------
P3ASORC_SERVICIO=chat
P3ASORC_SISTEMA=linux

# NO TOCAR
P3ASORC_MEMORIA=/home/ivan/SUPERMEMORIA/$P3ASORC_SERVICIO
P3ASORC_CONFIG=$P3ASORC_MEMORIA/ficheros_configuracion
P3ASORC_LOG=$P3ASORC_MEMORIA/$P3ASORC_SISTEMA.log
P3ASORC_HISTORIAL=$P3ASORC_MEMORIA/history$P3ASORC_SISTEMA.txt

# ---
P3ASORC_CHAT_DOMAIN=$(hostname -f)
P3ASORC_CHAT_USER1=usuario_chat1
P3ASORC_CHAT_USER2=usuario_chat2
P3ASORC_CHAT_PASS=1

# Rutas de configuración y logs de ejabberd
P3ASORC_CHAT_CONFIG_FILE=/etc/ejabberd/ejabberd.yml
P3ASORC_CHAT_LOG_DIR=/var/log/ejabberd
P3ASORC_CHAT_LOG_FILE=$P3ASORC_CHAT_LOG_DIR/ejabberd.log

#-------------------------------------------------------
# Servicio
#-------------------------------------------------------
# PASO 1: Paquetes y limpieza
rm -rf $P3ASORC_CHAT_LOG_FILE
apt remove -y ejabberd
apt install -y ejabberd

# PASO 2: Configuración
cat << EOF > $P3ASORC_CHAT_CONFIG_FILE
loglevel: debug
log_rotate_count: 0
hosts:
  - $P3ASORC_CHAT_DOMAIN
  - localhost

certfiles:
  - "/etc/ejabberd/ejabberd.pem"

define_macro:
  'TLS_CIPHERS': "HIGH:!aNULL:!eNULL:!3DES:@STRENGTH"
  'TLS_OPTIONS':
    - "no_sslv3"
    - "no_tlsv1"
    - "no_tlsv1_1"
    - "cipher_server_preference"
    - "no_compression"

c2s_ciphers: 'TLS_CIPHERS'
s2s_ciphers: 'TLS_CIPHERS'
c2s_protocol_options: 'TLS_OPTIONS'
s2s_protocol_options: 'TLS_OPTIONS'

listen:
  -
    port: 5222
    ip: "::"
    module: ejabberd_c2s
    max_stanza_size: 262144
    shaper: c2s_shaper
    access: c2s
    starttls_required: true
    protocol_options: 'TLS_OPTIONS'
  -
    port: 5223
    ip: "::"
    module: ejabberd_c2s
    max_stanza_size: 262144
    shaper: c2s_shaper
    access: c2s
    tls: true
    protocol_options: 'TLS_OPTIONS'
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
    protocol_options: 'TLS_OPTIONS'
    request_handlers:
      /api: mod_http_api
      /bosh: mod_bosh
      /ws: ejabberd_http_ws
  -
    port: 5280
    ip: "::"
    module: ejabberd_http
    tls: true
    protocol_options: 'TLS_OPTIONS'
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

disable_sasl_mechanisms:
  - "digest-md5"
  - "X-OAUTH2"

s2s_use_starttls: required
auth_password_format: scram
acl:
  admin:
     user:
       - ""

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
  "admin access":
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
  fast: 200000

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
  mod_fail2ban: {}
  mod_http_api: {}
  mod_last: {}
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
  mod_offline:
    access_max_user_messages: max_user_offline_messages
  mod_ping: {}
  mod_pres_counter:
    count: 5
    interval: 60
  mod_privacy: {}
  mod_private: {}
  mod_pubsub:
    access_createnode: pubsub_createnode
    plugins:
      - flat
      - pep
    force_node_config:
      "eu.siacs.conversations.axolotl.*":
        access_model: open
      storage:bookmarks:
        access_model: whitelist
  mod_push: {}
  mod_push_keepalive: {}
  mod_roster:
    versioning: true
  mod_s2s_bidi: {}
  mod_s2s_dialback: {}
  mod_shared_roster: {}
  mod_sic: {}
  mod_stream_mgmt:
    resend_on_timeout: if_offline
  mod_stun_disco: {}
  mod_vcard:
    search: false
  mod_vcard_xupdate: {}
  mod_version: {}
EOF

# PASO 3: Permisos y aplicar cambios
chown ejabberd:ejabberd $P3ASORC_CHAT_CONFIG_FILE
chmod 640 $P3ASORC_CHAT_CONFIG_FILE
systemctl stop ejabberd
systemctl enable ejabberd
systemctl start ejabberd
sleep 20

# PASO 4: Registro de usuarios
ejabberdctl unregister $P3ASORC_CHAT_USER1 $P3ASORC_CHAT_DOMAIN
ejabberdctl unregister $P3ASORC_CHAT_USER2 $P3ASORC_CHAT_DOMAIN
ejabberdctl register $P3ASORC_CHAT_USER1 $P3ASORC_CHAT_DOMAIN $P3ASORC_CHAT_PASS
ejabberdctl register $P3ASORC_CHAT_USER2 $P3ASORC_CHAT_DOMAIN $P3ASORC_CHAT_PASS

#-------------------------------------------------------
# Valida servicio
#-------------------------------------------------------
systemctl status ejabberd --no-pager
# Verificar puertos (52** es cliente-servidor, 5280 es web admin)
netstat -tunelp | grep -E 'beam|epmd'

#-------------------------------------------------------
# Extraer logs, configs e historial
#-------------------------------------------------------
rm -rf $P3ASORC_MEMORIA
mkdir -p $P3ASORC_MEMORIA
mkdir -p $P3ASORC_CONFIG

cp $P3ASORC_CHAT_CONFIG_FILE $P3ASORC_CONFIG
cp $P3ASORC_CHAT_LOG_FILE $P3ASORC_LOG

history > $P3ASORC_HISTORIAL
chmod 777 -R $P3ASORC_MEMORIA

tree $P3ASORC_MEMORIA

#-------------------------------------------------------
# Comprobación desde host
#-------------------------------------------------------
sudo dnf install -y pidgin

pidgin -m
