#!/usr/bin/env bash
# From Neha (Developer): recreates last night's incident on the STAGING server.
# Never run this in production.
mkdir -p /var/log/brewcart

# Normal daily API logs, some of them weeks old
for d in 1 3 5 8 12 20 35 45 60; do
  f="/var/log/brewcart/api-$(date -d "-$d days" +%F).log"
  yes "$(date -d "-$d days" '+%F %T') INFO GET /api/orders 200 12ms" | head -c 3M > "$f"
  touch -d "-$d days" "$f"
done

# The bug: debug logging was left on in the release, and it writes until the disk is full
yes "$(date '+%F %T') DEBUG cache miss key=menu:42 payload={size:2048,ttl:0}" \
  > /var/log/brewcart/debug.log 2>/dev/null

echo "Incident simulated."
