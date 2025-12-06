#!/usr/bin/env bash
set -uo pipefail

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  echo '{"message_metadata": {}, "observability": {}, "payload": {"result": "error", "output_data": {}}, "error": {"code": 500, "message": "jq is required"}}'
  exit 1
fi

MESSAGE_METADATA=$(echo "$INPUT" | jq -c '.message_metadata // {}')
OBSERVABILITY=$(echo "$INPUT" | jq -c '.observability // {}')
PARAMS=$(echo "$INPUT" | jq -c '.payload.input_parameters // {}')

SERVICE_STATE="simulated"
ERROR_MSG=""

if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files docker.service >/dev/null 2>&1; then
  if systemctl restart docker >/dev/null 2>&1; then
    SERVICE_STATE=$(systemctl is-active docker 2>/dev/null || echo "unknown")
  else
    ERROR_MSG="systemctl restart docker failed"
  fi
else
  SERVICE_STATE="simulated"
fi

if [[ -n "$ERROR_MSG" ]]; then
  printf '%s\n' "{\"message_metadata\":$MESSAGE_METADATA,\"observability\":$OBSERVABILITY,\"payload\":{\"result\":\"error\",\"output_data\":{}},\"error\":{\"code\":1,\"message\":\"$ERROR_MSG\"}}"
  exit 1
fi

OUTPUT_DATA=$(jq -n --arg state "$SERVICE_STATE" --argjson params "$PARAMS" '{service_state: $state, input_parameters: $params}')
printf '%s\n' "{\"message_metadata\":$MESSAGE_METADATA,\"observability\":$OBSERVABILITY,\"payload\":{\"result\":\"success\",\"output_data\":$OUTPUT_DATA},\"error\":null}"
