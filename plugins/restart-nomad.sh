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
CHECK_JOBS=$(echo "$PARAMS" | jq -r '.check_jobs // false')

SERVICE_STATE="simulated"
JOB_SUMMARY=""
ERROR_MSG=""

if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files nomad.service >/dev/null 2>&1; then
  if systemctl restart nomad >/dev/null 2>&1; then
    SERVICE_STATE=$(systemctl is-active nomad 2>/dev/null || echo "unknown")
  else
    ERROR_MSG="systemctl restart nomad failed"
  fi
else
  SERVICE_STATE="simulated"
fi

if [[ "$CHECK_JOBS" == "true" ]] && command -v nomad >/dev/null 2>&1; then
  JOB_SUMMARY=$(nomad job status 2>/dev/null | head -n 5 | tr -s ' ')
fi

if [[ -n "$ERROR_MSG" ]]; then
  printf '%s\n' "{\"message_metadata\":$MESSAGE_METADATA,\"observability\":$OBSERVABILITY,\"payload\":{\"result\":\"error\",\"output_data\":{}},\"error\":{\"code\":1,\"message\":\"$ERROR_MSG\"}}"
  exit 1
fi

OUTPUT_DATA=$(jq -n --arg state "$SERVICE_STATE" --arg jobs "$JOB_SUMMARY" --argjson params "$PARAMS" '{service_state: $state, job_status: $jobs, input_parameters: $params}')
printf '%s\n' "{\"message_metadata\":$MESSAGE_METADATA,\"observability\":$OBSERVABILITY,\"payload\":{\"result\":\"success\",\"output_data\":$OUTPUT_DATA},\"error\":null}"
