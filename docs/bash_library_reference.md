# Bash library reference

`rune_bpcs.sh` is a shared Bash helper library that implements the Bash Plugin Communication Specification (BPCS) for Bash based plugins.

The library exists to keep plugins simple and consistent. Plugins should not hand roll JSON parsing or output formatting.

## What the library does

- reads and validates the BPCS input JSON from stdin
- provides helpers for reading parameters and metadata safely
- builds the BPCS output JSON envelope
- enforces stdout and exit code conventions

## Expected environment

Recommended dependencies:

- `jq` for safe JSON handling

If `jq` is not available, the library may fall back to limited parsing. In corporate environments, standardizing on `jq` is strongly recommended.

## Common functions

### `rune_param KEY DEFAULT`

Returns an input parameter value from the BPCS input payload:

```bash
SERVICE=$(rune_param "service" "")
```

### `rune_meta KEY DEFAULT`

Returns metadata fields (such as `trace_id`, `correlation_id`, `node`) that the LMM injected into the BPCS input.

```bash
TRACE_ID=$(rune_meta "trace_id" "none")
NODE=$(rune_meta "node" "unknown")
```

### `rune_ok MESSAGE JSON_OBJECT_STRING`

Emits a BPCS success output to stdout and exits `0`.

```bash
rune_ok "Completed" "$(jq -n '{ok:true}')"
```

Output shape:

```json
{
  "payload": {
    "result": "success",
    "output_data": { "ok": true }
  },
  "error": null
}
```

### `rune_fail CODE MESSAGE JSON_DETAILS_STRING`

Emits a BPCS error output to stdout and exits non zero.

```bash
rune_fail 2 "Resource not found" "$(jq -n --arg path "/var/lib/app" '{path:$path}')"
```

Output shape:

```json
{
  "payload": null,
  "error": {
    "code": 2,
    "message": "Resource not found",
    "details": { "path": "/var/lib/app" }
  }
}
```

## Exit code conventions

The library is designed to align with BPCS conventions:

- `0` success
- `1` validation errors
- `2` resource or dependency errors
- `3` business logic failures
- `4` configuration errors
- `100` unhandled exceptions

The LMM interprets plugin exit codes and error payloads and will normalize failures into EPS for upstream handling.

## Plugin guidance

- stdout must contain only the one JSON object
- stderr is allowed for diagnostics, but should not contain structured data
- do not print secrets
- keep plugins small and single purpose
