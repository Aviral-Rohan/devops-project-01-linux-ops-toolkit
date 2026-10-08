#!/usr/bin/env bash
# onboard_user.sh - create a Linux user and install their SSH public key
# Usage: sudo ./onboard_user.sh <username> <public_key_file> [group]

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root (use sudo)." >&2
  exit 1
fi

if [ $# -lt 2 ]; then
  echo "Usage: $0 <username> <public_key_file> [group]" >&2
  exit 1
fi

USERNAME="$1"
KEY_FILE="$2"
GROUP="${3:-developers}"

[ -f "$KEY_FILE" ] || { echo "Key file not found: $KEY_FILE" >&2; exit 1; }

getent group "$GROUP" >/dev/null || { groupadd "$GROUP"; echo "Created group $GROUP"; }

if id "$USERNAME" >/dev/null 2>&1; then
  echo "User $USERNAME already exists, skipping creation"
else
  useradd -m -s /bin/bash -G "$GROUP" "$USERNAME"
  echo "Created user $USERNAME"
fi
usermod -aG "$GROUP" "$USERNAME"

HOME_DIR=$(getent passwd "$USERNAME" | cut -d: -f6)
install -d -m 700 -o "$USERNAME" -g "$USERNAME" "$HOME_DIR/.ssh"
AUTH="$HOME_DIR/.ssh/authorized_keys"
touch "$AUTH"

if grep -qxF "$(cat "$KEY_FILE")" "$AUTH"; then
  echo "Key already installed"
else
  cat "$KEY_FILE" >> "$AUTH"
  echo "Key installed"
fi
chown "$USERNAME:$USERNAME" "$AUTH"
chmod 600 "$AUTH"

echo "Done: $(id "$USERNAME")"