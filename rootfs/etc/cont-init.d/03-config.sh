#!/usr/bin/with-contenv sh
# shellcheck shell=sh

#WAN_IP=${WAN_IP:-10.0.0.1}
#WAN_IP_CMD=${WAN_IP_CMD:-"dig +short myip.opendns.com @resolver1.opendns.com"}

TZ=${TZ:-UTC}
MEMORY_LIMIT=${MEMORY_LIMIT:-256M}
UPLOAD_MAX_SIZE=${UPLOAD_MAX_SIZE:-16M}
CLEAR_ENV=${CLEAR_ENV:-yes}
OPCACHE_MEM_SIZE=${OPCACHE_MEM_SIZE:-128}
MAX_FILE_UPLOADS=${MAX_FILE_UPLOADS:-50}
AUTH_DELAY=${AUTH_DELAY:-0s}
REAL_IP_FROM=${REAL_IP_FROM:-0.0.0.0/32}
REAL_IP_HEADER=${REAL_IP_HEADER:-X-Forwarded-For}
LOG_IP_VAR=${LOG_IP_VAR:-remote_addr}
LOG_ACCESS=${LOG_ACCESS:-true}
XMLRPC_SIZE_LIMIT=${XMLRPC_SIZE_LIMIT:-1M}

XMLRPC_AUTHBASIC_STRING=${XMLRPC_AUTHBASIC_STRING:-rTorrent XMLRPC restricted access}
RUTORRENT_AUTHBASIC_STRING=${RUTORRENT_AUTHBASIC_STRING:-ruTorrent restricted access}
WEBDAV_AUTHBASIC_STRING=${WEBDAV_AUTHBASIC_STRING:-WebDAV restricted access}

RT_LOG_LEVEL=${RT_LOG_LEVEL:-info}
RT_LOG_EXECUTE=${RT_LOG_EXECUTE:-false}
RT_LOG_XMLRPC=${RT_LOG_XMLRPC:-false}
RT_SESSION_SAVE_SECONDS=${RT_SESSION_SAVE_SECONDS:-3600}
RT_TRACKER_DELAY_SCRAPE=${RT_TRACKER_DELAY_SCRAPE:-true}
RT_SEND_BUFFER_SIZE=${RT_SEND_BUFFER_SIZE:-4M}
RT_RECEIVE_BUFFER_SIZE=${RT_RECEIVE_BUFFER_SIZE:-4M}
RT_PREALLOCATE_TYPE=${RT_PREALLOCATE_TYPE:-0}

RU_REMOVE_CORE_PLUGINS=${RU_REMOVE_CORE_PLUGINS:-false}
RU_HTTP_USER_AGENT=${RU_HTTP_USER_AGENT:-Mozilla/5.0 (Windows NT 6.0; WOW64; rv:12.0) Gecko/20100101 Firefox/12.0}
RU_HTTP_TIME_OUT=${RU_HTTP_TIME_OUT:-30}
RU_HTTP_USE_GZIP=${RU_HTTP_USE_GZIP:-true}
RU_RPC_TIME_OUT=${RU_RPC_TIME_OUT:-5}
RU_LOG_RPC_CALLS=${RU_LOG_RPC_CALLS:-false}
RU_LOG_RPC_FAULTS=${RU_LOG_RPC_FAULTS:-true}
RU_PHP_USE_GZIP=${RU_PHP_USE_GZIP:-false}
RU_PHP_GZIP_LEVEL=${RU_PHP_GZIP_LEVEL:-2}
RU_SCHEDULE_RAND=${RU_SCHEDULE_RAND:-10}
RU_LOG_FILE=${RU_LOG_FILE:-/data/rutorrent/rutorrent.log}
RU_DO_DIAGNOSTIC=${RU_DO_DIAGNOSTIC:-true}
RU_CACHED_PLUGIN_LOADING=${RU_CACHED_PLUGIN_LOADING:-false}
RU_SAVE_UPLOADED_TORRENTS=${RU_SAVE_UPLOADED_TORRENTS:-true}
RU_OVERWRITE_UPLOADED_TORRENTS=${RU_OVERWRITE_UPLOADED_TORRENTS:-false}
RU_FORBID_USER_SETTINGS=${RU_FORBID_USER_SETTINGS:-false}
RU_LOCALE=${RU_LOCALE:-UTF8}

RT_DHT_PORT=${RT_DHT_PORT:-6881}
RT_INC_PORT=${RT_INC_PORT:-50000}
XMLRPC_PORT=${XMLRPC_PORT:-8000}
XMLRPC_HEALTH_PORT=$((XMLRPC_PORT + 1))
RUTORRENT_PORT=${RUTORRENT_PORT:-8080}
RUTORRENT_HEALTH_PORT=$((RUTORRENT_PORT + 1))
WEBDAV_PORT=${WEBDAV_PORT:-9000}
WEBDAV_HEALTH_PORT=$((WEBDAV_PORT + 1))

# WAN IP
if [ -z "$WAN_IP" ] && [ -n "$WAN_IP_CMD" ]; then
  WAN_IP=$(eval "$WAN_IP_CMD")
fi
if [ -n "$WAN_IP" ]; then
  echo "Public IP address enforced to ${WAN_IP}"
fi
printf "%s" "$WAN_IP" > /var/run/s6/container_environment/WAN_IP

# Timezone
echo "Setting timezone to ${TZ}..."
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone

# Healthcheck
echo "Update healthcheck script..."
cat > /usr/local/bin/healthcheck <<EOL
#!/bin/sh
set -e

# rTorrent
curl --fail -H "Content-Type: text/xml" -d "<?xml version='1.0'?><methodCall><methodName>system.api_version</methodName></methodCall>" http://127.0.0.1:${XMLRPC_HEALTH_PORT}

# ruTorrent / PHP
curl --fail http://127.0.0.1:${RUTORRENT_HEALTH_PORT}/ping

# WebDAV
curl --fail http://127.0.0.1:${WEBDAV_HEALTH_PORT}
EOL

# Init
echo "Initializing files and folders..."
mkdir -p /data/geoip \
  /data/rtorrent/log \
  /data/rtorrent/.session \
  /data/rtorrent/watch \
  /data/rutorrent/conf/users \
  /data/rutorrent/plugins \
  /data/rutorrent/plugins-conf \
  /data/rutorrent/share/users \
  /data/rutorrent/share/torrents \
  /data/rutorrent/themes \
  /downloads/complete \
  /downloads/temp
touch /passwd/rpc.htpasswd \
  /passwd/rutorrent.htpasswd \
  /passwd/webdav.htpasswd \
  /data/rtorrent/log/rtorrent.log \
  "${RU_LOG_FILE}"
rm -f /data/rtorrent/.session/rtorrent.lock

# rTorrent local config
echo "Checking rTorrent local configuration..."
sed -e "s!@RT_LOG_LEVEL@!$RT_LOG_LEVEL!g" \
  -e "s!@RT_DHT_PORT@!$RT_DHT_PORT!g" \
  -e "s!@RT_INC_PORT@!$RT_INC_PORT!g" \
  -e "s!@XMLRPC_SIZE_LIMIT@!$XMLRPC_SIZE_LIMIT!g" \
  -e "s!@RT_SESSION_SAVE_SECONDS@!$RT_SESSION_SAVE_SECONDS!g" \
  -e "s!@RT_TRACKER_DELAY_SCRAPE@!$RT_TRACKER_DELAY_SCRAPE!g" \
  -e "s!@RT_SEND_BUFFER_SIZE@!$RT_SEND_BUFFER_SIZE!g" \
  -e "s!@RT_RECEIVE_BUFFER_SIZE@!$RT_RECEIVE_BUFFER_SIZE!g" \
  -e "s!@RT_PREALLOCATE_TYPE@!$RT_PREALLOCATE_TYPE!g" \
  /tpls/etc/rtorrent/.rtlocal.rc > /etc/rtorrent/.rtlocal.rc
if [ "${RT_LOG_EXECUTE}" = "true" ]; then
  echo "  Enabling rTorrent execute log..."
  sed -i "s!#log\.execute.*!log\.execute = (cat,(cfg.logs),\"execute.log\")!g" /etc/rtorrent/.rtlocal.rc
fi
if [ "${RT_LOG_XMLRPC}" = "true" ]; then
  echo "  Enabling rTorrent xmlrpc log..."
  sed -i "s!#log\.xmlrpc.*!log\.xmlrpc = (cat,(cfg.logs),\"xmlrpc.log\")!g" /etc/rtorrent/.rtlocal.rc
fi

# rTorrent config
echo "Checking rTorrent configuration..."
if [ ! -f /data/rtorrent/.rtorrent.rc ]; then
  echo "  Creating default configuration..."
  cp /tpls/.rtorrent.rc /data/rtorrent/.rtorrent.rc
  cp /tpls/_rtlocal.rc /data/rtorrent/_rtlocal.rc
fi
if [ ! -f /data/rtorrent/_rtlocal.rc  ]; then
  echo "  Creating default configuration..."
  cp /tpls/_rtlocal.rc /data/rtorrent/_rtlocal.rc
fi
chown rtorrent:rtorrent /data/rtorrent/.rtorrent.rc
chown rtorrent:rtorrent /data/rtorrent/_rtlocal.rc

echo "Fixing perms..."
chown rtorrent:rtorrent \
  /data/rutorrent/share/users \
  /data/rutorrent/share/torrents \
  /downloads \
  /downloads/complete \
  /downloads/temp \
  "${RU_LOG_FILE}"
chown -R rtorrent:rtorrent \
  /data/geoip \
  /data/rtorrent/log \
  /data/rtorrent/.session \
  /data/rtorrent/watch \
  /data/rutorrent/conf \
  /data/rutorrent/plugins \
  /data/rutorrent/plugins-conf \
  /data/rutorrent/share \
  /data/rutorrent/themes \
  /etc/rtorrent
chmod 644 \
  /data/rtorrent/.rtorrent.rc \
  /passwd/*.htpasswd \
  /etc/rtorrent/.rtlocal.rc
