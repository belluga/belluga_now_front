---
trigger: model_decision
description: "At session start/end or when the user requests lifecycle actions."
---

## Rule
When a session begins, switches scope, or ends:
- Load the Persona Selection Workflow to anchor the persona.
- Execute the Session Lifecycle Workflow (`delphi-ai/workflows/docker/session-lifecycle-method.md`) to log purpose, freeze work during instruction edits, and manage transitions.
- At session end, follow `delphi-ai/workflows/docker/post-session-review-method.md`: analyze new principles, update mandates if needed, and deliver English feedback before acknowledging closure.

## Rationale
Session lifecycle discipline keeps context consistent across personas, ensures instruction updates trigger session restarts, and enforces the mandated post-session review steps.

## Enforcement
- Trigger this rule whenever the user says “session start/end,” changes modules, or requests review.
- Do not proceed to new tasks until persona + lifecycle steps are complete.

## Notes
If instructions change mid-session, finish the change and do not proceed to architectural work until the updated instruction files have been explicitly reloaded (re-read) and confirmed.
