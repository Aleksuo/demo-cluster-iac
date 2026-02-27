#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

for script in scripts/bootstrap/[0-9][0-9]_*.sh; do
  [ -e "$script" ] || {
    echo "No bootstrap scripts found in scripts/bootstrap" >&2
    exit 1
  }
  echo "==> Running $(basename "${script}")"
  "${script}"
done
