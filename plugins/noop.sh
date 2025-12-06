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

OUTPUT_DATA=$(jq -n --argjson params "$PARAMS" '{action: "noop", input_parameters: $params}')
printf '%s\n' "{\"message_metadata\":$MESSAGE_METADATA,\"observability\":$OBSERVABILITY,\"payload\":{\"result\":\"success\",\"output_data\":$OUTPUT_DATA},\"error\":null}"
