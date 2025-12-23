---
trigger: model_decision
description: "When a session starts or environment/setup tasks are requested."
---

## Rule
When the context indicates environment setup, repository verification, or session start:
- Run the Initialization Checklist (`delphi-ai/initialization_checklist.md`) and `tools/verify_context.sh`.
- Execute the Environment Readiness Workflow (`delphi-ai/workflows/docker/environment-readiness-method.md`) to confirm submodule links, permissions, and README guidance.
- Document any remediation (symlinks, ownership fixes) before moving to feature work.
 - If tactical TODO discipline is in use, ensure `foundation_documentation/todos/{active,completed}` exists (create via `tools/verify_context.sh --fix-todos` if desired).

## Rationale
Proper initialization prevents stale instructions, broken symlinks, and container permissions issues. Automating this via a rule ensures the workspace reaches a known-good state before touching code.

## Enforcement
- Triggered automatically at session start and whenever the user mentions setup/CI/CD/env readiness.
- Block other workflows until the checklist passes.

## Notes
If `verify_context.sh` fails due to missing symlinks, pause, fix the issue, and rerun the script before continuing.
