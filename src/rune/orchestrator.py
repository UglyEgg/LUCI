from __future__ import annotations

"""Lifecycle Orchestration Module for RUNE."""

from pathlib import Path
from typing import Any
from rune.mediator import execute_action
from rune.models import (
    ActionMetadata,
    MediatorResult,
    OrchestrationResult,
    StructuredError,
    build_message_metadata,
    build_observability,
)

PLUGINS_DIR = Path(__file__).resolve().parent.parent / "plugins"

ACTION_REGISTRY: dict[str, ActionMetadata] = {
    "gather-logs": ActionMetadata(
        name="gather-logs",
        description="Collect system logs and package them into an archive.",
        plugin_path=PLUGINS_DIR / "gather-logs.sh",
    ),
    "restart-docker": ActionMetadata(
        name="restart-docker",
        description="Restart the Docker daemon via systemd.",
        plugin_path=PLUGINS_DIR / "restart-docker.sh",
    ),
    "restart-nomad": ActionMetadata(
        name="restart-nomad",
        description="Restart the Nomad agent and optionally summarize jobs.",
        plugin_path=PLUGINS_DIR / "restart-nomad.sh",
    ),
    "noop": ActionMetadata(
        name="noop",
        description="No-op plugin used for connectivity and contract testing.",
        plugin_path=PLUGINS_DIR / "noop.sh",
    ),
}


def list_actions() -> list[ActionMetadata]:
    """Return available actions registered with the orchestrator."""

    return list(ACTION_REGISTRY.values())


def _build_payload(params: dict[str, Any]) -> dict[str, Any]:
    message_metadata = build_message_metadata()
    observability = build_observability()
    return {
        "message_metadata": message_metadata,
        "payload": {"input_parameters": params},
        "observability": observability,
    }


def run_action(
    action: str,
    node: str,
    use_ssm: bool,
    dry_run: bool,
    params: dict[str, Any],
) -> OrchestrationResult:
    """Validate and execute a registered action."""

    metadata = ACTION_REGISTRY.get(action)
    if not metadata:
        message_metadata = build_message_metadata()
        observability = build_observability()
        error = StructuredError(code=404, message=f"Unknown action '{action}'")
        return OrchestrationResult(
            status="failed",
            action=action,
            node=node,
            transport=None,
            message_metadata=message_metadata,
            observability=observability,
            plugin_output=None,
            error=error,
        )

    if dry_run:
        message_metadata = build_message_metadata()
        observability = build_observability()
        payload = {
            "message_metadata": message_metadata,
            "observability": observability,
            "payload": {
                "result": "dry_run",
                "output_data": {
                    "action": action,
                    "node": node,
                    "input_parameters": params,
                },
            },
            "error": None,
        }
        return OrchestrationResult(
            status="dry_run",
            action=action,
            node=node,
            transport="ssm" if use_ssm else "ssh",
            message_metadata=message_metadata,
            observability=observability,
            plugin_output=payload,
            error=None,
        )

    payload = _build_payload(params)
    transport = "ssm" if use_ssm else "ssh"
    mediator_result: MediatorResult = execute_action(
        action=action,
        node=node,
        plugin_path=metadata.plugin_path,
        payload=payload,
        transport=transport,
    )

    status = "success" if mediator_result.status == "success" else "failed"
    return OrchestrationResult(
        status=status,
        action=action,
        node=node,
        transport=transport,
        message_metadata=payload["message_metadata"],
        observability=payload["observability"],
        plugin_output=mediator_result.plugin_output,
        error=mediator_result.error,
    )
