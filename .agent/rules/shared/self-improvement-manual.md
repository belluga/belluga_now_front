---
trigger: manual
description: Run the self-improvement session workflow when explicitly requested.
---

## Rule
When the user initiates a “self improvement session” (or equivalent command), switch to instruction-only mode:
- Freeze architectural work and acknowledge that only `delphi-ai/` instruction files may change.
- Run the Self Improvement Workflow (`delphi-ai/workflows/docker/self-improvement-session-method.md`): plan instruction updates, apply them, verify agnosticism (`tools/verify_context.sh`), and summarize changes.
- After instruction refinements are complete and the user confirms scope is done, explicitly reload the updated instruction files before resuming normal work (or end the session if a hard boundary is preferred).

## Rationale
Self-improvement sessions modify core instructions; treating them as a manual workflow prevents stale directives and keeps the agent aligned with the canonical rules.

## Enforcement
- Trigger only when the user explicitly calls for a self-improvement session or uses the `/self-improvement` command.
- Reject any attempt to mix instruction edits with normal work in the same session.

## Notes
Remember to run the post-session review after closing the self-improvement session to capture any new mandates or feedback.
