#/usr/bin/env bash
set -euo pipefail

exec nixos-rebuild $1 \
  --use-substitutes \
  --use-remote-sudo \
  --target-host "$2" \
  --flake ".#$2"

