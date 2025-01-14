#/usr/bin/env bash
set -euo pipefail

exec nixos-rebuild switch \
  --use-substitutes \
  --log-format multiline \
  --use-remote-sudo \
  --fast \
  --build-host "$1" \
  --target-host "$1" \
  --flake ".#$1"

