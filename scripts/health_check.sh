#!/usr/bin/env bash
# health_check.sh - quick health report for a Linux server
# Usage: ./health_check.sh [disk_threshold_percent]

set -u
THRESHOLD="${1:-80}"
STATUS=0

echo "===== Health report: $(hostname) | $(date '+%F %T %Z') ====="

echo; echo "--- Uptime and load ---"
uptime

echo; echo "--- Memory ---"
free -h

echo; echo "--- Disk usage ---"
df -h / /var/log
for mount in / /var/log; do
  used=$(df --output=pcent "$mount" | tail -1 | tr -dc '0-9')
  if [ "$used" -ge "$THRESHOLD" ]; then
    echo "ALERT: $mount is ${used}% full (threshold ${THRESHOLD}%)"
    STATUS=1
  fi
done

echo; echo "--- Top 5 processes by memory ---"
ps aux --sort=-%mem | head -n 6

echo; echo "--- Listening ports ---"
ss -tulpn

echo
if [ "$STATUS" -eq 0 ]; then echo "RESULT: OK"; else echo "RESULT: ALERT"; fi
exit "$STATUS"