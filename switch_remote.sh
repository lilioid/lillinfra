#/usr/bin/env bash
set -euo pipefail

set -x
exec nixos-rebuild $1 \
  --use-substitutes \
  --fast \
  --use-remote-sudo \
  --target-host "$2" \
  --flake ".#$2"

