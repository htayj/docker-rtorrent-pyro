#!/usr/bin/with-contenv sh
# shellcheck shell=sh

echo "Fixing perms..."
mkdir -p /data/rtorrent \
  /data/rutorrent \
  /downloads \
  /passwd \
  /etc/rtorrent \
  /var/run/rtorrent
chown rtorrent:rtorrent \
  /data \
  /data/rtorrent \
  /data/rutorrent \
  /downloads
chown -R rtorrent:rtorrent \
  /etc/rtorrent \
  /passwd \
  /tpls \
  /var/run/rtorrent
