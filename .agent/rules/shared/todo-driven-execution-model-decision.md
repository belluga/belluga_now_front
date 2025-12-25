---
trigger: model_decision
description: "Before any implementation work (code/docs) that changes the project, require an explicit tactical TODO and resolve all COMMENT blocks."
---

## Rule
Before starting any implementation work that changes project code, submodule code, or project-specific documentation (`foundation_documentation/`), Delphi must operate from a tactical TODO file under `foundation_documentation/todos/active/`.

### Gate A — TODO existence
- If no relevant TODO exists, do not start implementation.
- Ask the user to create one (or ask permission to draft one), then proceed only after the TODO is present.

### Gate B — TODO refinement (no code)
- Read the TODO.
- Summarize `scope`, `out_of_scope`, `definition_of_done`, and `validation_steps`.
- Raise any missing questions/decisions that would materially change implementation, and update the TODO before proceeding.

### Gate C — COMMENT blocks (mandatory)
- Any block labeled **COMENTÁRIO:** (Portuguese) or **COMMENT:** (English) is treated as a contextual question/consideration about the content immediately following it.
- Do not start implementation until all COMMENT blocks are resolved.
- Resolution means: incorporate the outcome into the TODO (e.g., `decisions`, `scope`, `definition_of_done`) and remove the COMMENT block.
- If ambiguous, promote to `questions_to_close` and wait for user confirmation before removing.

### Gate D — Explicit approval token (mandatory)
- After Gates A–C, Delphi must ask for explicit user approval of the TODO before any implementation begins.
- The approval token is: **APROVADO**.
- Until the user replies with **APROVADO** (case-insensitive), Delphi must not:
  - call `apply_patch`,
  - run write commands that change project files,
  - or make any project/submodule/code/docs modifications.

## Rationale
This prevents scope creep and “hub refactors” by forcing a written, reviewable contract (scope + DoD) that must be validated before code begins.

## Enforcement
- If the user requests implementation without a TODO, block and request the TODO.
- If COMMENT blocks exist, block implementation until they are resolved and removed.

## Notes
- This rule is stack-agnostic and applies to Flutter/Laravel/Web as long as the implementation changes project artifacts.
- After completion, the TODO should be moved to `foundation_documentation/todos/completed/` (or marked canceled).
