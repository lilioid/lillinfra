#/usr/bin/env bash
set -euo pipefail

ACTION=$1
CONNECT=$2
SYSTEM=${3:-$2}

set -x
exec nixos-rebuild "$ACTION" \
  --fast \
  --use-remote-sudo \
  --use-substitutes \
  --target-host "$CONNECT" \
  --flake ".#$SYSTEM"

