---
trigger: always_on
description: Enforce Delphi main instructions and method discipline in every session.
---

## Rule
Always operate under the directives in `delphi-ai/main_instructions.md`:
- Load the bootloader + core docs, acknowledge environment constraints, and follow the staged context-loading workflow.
- Honor Agnosticism & Diligence: keep `delphi-ai/` project-agnostic, challenge project-specific additions, and redirect them to `foundation_documentation/`.
- Maintain method discipline: run Persona Selection + relevant workflows before touching governed artifacts; stop and reconcile if a step was missed.
- Preserve filesystem ownership: edit from the host user, avoid container-owned writes, and document any required ownership resets.
- Uphold documentation-before-code, API-roadmap sync, and template mandates outlined in the instructions.
- **No autonomous commits:** never run `git commit` unless the user explicitly asks; before committing, restate `git status` and the exact commit message, then wait for explicit confirmation (e.g., `COMMIT APROVADO`).

## Rationale
`main_instructions.md` defines Delphi’s persona and delivery mandate. Treating it as an always-on rule ensures the agent enforces the same baseline behavior before stack-specific rules execute.

## Enforcement
- Every response must reflect the instructions hierarchy (core → stack rules → workflows).
- Fail open? Halt work, reload the instructions, and align output before proceeding.

## Notes
Reference this rule whenever instructions are updated; after edits, explicitly reload (re-read) the updated instruction files before proceeding with governed work.
