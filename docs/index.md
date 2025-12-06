# Welcome to RUNE

**RUNE (Remediation & Unified Node Executor)** is a focused, standards-driven automation framework for rapid, reliable remote remediation across Linux systems.

When an alert fires and time matters, RUNE lets operators and systems trigger structured, safe, repeatable actions — such as gathering logs, restarting services, or running diagnosis plugins — with a single CLI command or dashboard button.

RUNE is built for **incident response**, **SoC operations**, and **SRE on-call workflows**, not as yet another configuration-management clone.

---

## Why RUNE?

Most automation tools (Ansible, Salt, StackStorm, etc.) solve **large, complex, stateful** problems.  
RUNE solves a different one:

> _“Do this one action on that one node **right now** and give me structured output I can trust.”_

RUNE is:

- **Agentless** — remote hosts need nothing installed
- **Protocol-driven** — RCS, EPS, and BPCS define all communication
- **Script-friendly** — plugins are just Bash or Python
- **Machine-consumable** — always returns structured JSON
- **Dashboards-ready** — integrates cleanly with SoC and SRE tooling

RUNE is intentionally small — the scalpel that complements the automation sledgehammers.

Learn more:  
➡️ [Why RUNE?](why_rune.md)

© 2025 Richard Majewski. Licensed under the MPL-2.0.
