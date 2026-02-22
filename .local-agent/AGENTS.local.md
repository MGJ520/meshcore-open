# Local Agent Operating Rules (Untracked)

This file is NOT version-controlled.
It overrides default agent behavior for this workstation only.

---

## Core Behavior

- Always search the codebase before editing.
- Produce a short plan before modifying BLE or protocol logic.
- Never modify BLE frame structure or command codes without explicit approval.
- After editing connector code, re-check command/response mappings.
- Never perform destructive operations (delete files, mass refactor) without confirmation.

---

## Protocol Discipline

- maxFrameSize must remain 172 unless explicitly instructed.
- Identity hash size is 1 byte (PATH_HASH_SIZE).
- Companion radio formats must not change silently.
- Command codes and response codes must remain backward-compatible.

---

## Coding Discipline

- Keep modifications minimal.
- Prefer refactoring over rewriting.
- Follow existing Flutter patterns (StatelessWidget + Consumer).
- Avoid premature abstraction.
- Explain what changed and why.

---

## Learning Mode

When discovering:
- a working build command
- a protocol quirk
- a confirmed packet layout rule

Append a concise bullet to:

.local-agent/memory.local.md

Keep memory under 15 bullets max.
