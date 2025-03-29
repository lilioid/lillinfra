#/usr/bin/env bash
set -euo pipefail

ACTION=$1
CONNECT=$2
SYSTEM=$3

set -x
exec nixos-rebuild "$ACTION" \
  --use-substitutes \
  --fast \
  --use-remote-sudo \
  --target-host "$CONNECT" \
  --flake ".#$SYSTEM"

