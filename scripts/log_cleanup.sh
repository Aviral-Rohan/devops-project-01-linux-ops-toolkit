#!/usr/bin/env bash
# log_cleanup.sh - compress logs older than 7 days, delete logs older than 30 days
# Usage: ./log_cleanup.sh [--dry-run] [log_dir]

set -euo pipefail

DRY_RUN=false
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=true
  shift
fi

LOG_DIR="${1:-/var/log/brewcart}"
COMPRESS_AFTER=7
DELETE_AFTER=30

run() {
  if [ "$DRY_RUN" = true ]; then
    echo "[dry-run] would run: $*"
  else
    echo "[run] $*"
    "$@"
  fi
}

echo "Log cleanup in $LOG_DIR (dry run: $DRY_RUN)"
echo "Size before: $(du -sh "$LOG_DIR" | cut -f1)"

echo "--- Deleting logs older than $DELETE_AFTER days ---"
find "$LOG_DIR" -type f \( -name '*.log' -o -name '*.log.gz' \) -mtime +"$DELETE_AFTER" -print0 |
  while IFS= read -r -d '' f; do run rm -f "$f"; done

echo "--- Compressing logs older than $COMPRESS_AFTER days ---"
find "$LOG_DIR" -type f -name '*.log' -mtime +"$COMPRESS_AFTER" ! -mtime +"$DELETE_AFTER" -print0 |
  while IFS= read -r -d '' f; do run gzip "$f"; done

echo "Size after: $(du -sh "$LOG_DIR" | cut -f1)"