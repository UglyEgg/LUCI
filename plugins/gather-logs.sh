#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  echo '{"message_metadata": {}, "observability": {}, "payload": {"result": "error", "output_data": {}}, "error": {"code": 500, "message": "jq is required"}}'
  exit 1
fi

MESSAGE_METADATA=$(echo "$INPUT" | jq -c '.message_metadata // {}')
OBSERVABILITY=$(echo "$INPUT" | jq -c '.observability // {}')
PARAMS=$(echo "$INPUT" | jq -c '.payload.input_parameters // {}')
WORK_DIR=$(mktemp -d /tmp/rune-logs-XXXXXX)
ARTIFACT=$(mktemp /tmp/rune-logs-XXXXXX.tar.gz)
ENTRIES=0

include_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    cp "$path" "$WORK_DIR"/$(basename "$path")
    ENTRIES=$((ENTRIES + 1))
  fi
}

if command -v journalctl >/dev/null 2>&1; then
  journalctl --no-pager >"$WORK_DIR/journalctl.log" 2>/dev/null || true
  ENTRIES=$((ENTRIES + 1))
fi

if [[ -f /var/log/syslog ]]; then
  cp /var/log/syslog "$WORK_DIR"/syslog || true
  ENTRIES=$((ENTRIES + 1))
elif [[ -f /var/log/messages ]]; then
  cp /var/log/messages "$WORK_DIR"/messages || true
  ENTRIES=$((ENTRIES + 1))
fi

EXTRA_PATHS=$(echo "$PARAMS" | jq -r '.extra_paths[]?')
for path in $EXTRA_PATHS; do
  include_file "$path"
done

tar -czf "$ARTIFACT" -C "$WORK_DIR" . >/dev/null 2>&1 || true
OUTPUT_DATA=$(jq -n --arg path "$ARTIFACT" --argjson count $ENTRIES '{artifact_path: $path, entries_collected: $count}')

printf '%s\n' "{\"message_metadata\":$MESSAGE_METADATA,\"observability\":$OBSERVABILITY,\"payload\":{\"result\":\"success\",\"output_data\":$OUTPUT_DATA},\"error\":null}"
