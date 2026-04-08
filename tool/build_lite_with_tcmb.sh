#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KEY_FILE="$ROOT_DIR/tcmb.txt"

if [[ ! -f "$KEY_FILE" ]]; then
  echo "tcmb.txt bulunamadı: $KEY_FILE"
  exit 1
fi

TCMB_API_KEY="$(sed 's/.*: *//' "$KEY_FILE" | tr -d '[:space:]')"

if [[ -z "$TCMB_API_KEY" ]]; then
  echo "tcmb.txt içinde geçerli bir anahtar bulunamadı."
  exit 1
fi

cd "$ROOT_DIR"
exec flutter build apk --flavor lite -t lib/main_lite.dart --dart-define=TCMB_API_KEY="$TCMB_API_KEY" "$@"
