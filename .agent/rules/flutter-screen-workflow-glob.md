---
trigger: always_on
description: 
---

## Rule
Whenever a file under `flutter-app/lib/presentation/**/screens/**` is active or modified, run the Screen Workflow:
- Load and reference `foundation_documentation/policies/scope_subscope_governance.md` before placement/ownership decisions.
- Keep screens pure UI; all logic/state lives in controllers per the architecture rule.
- Ensure each screen is attributed to a canonical scope/subscope boundary; reject ambiguous legacy placement.
- Ensure ModuleScope/GetIt registrations and documentation updates (`screens/*.md`) accompany the change.
- Do not introduce undefined subscopes or ad-hoc scope folders without explicit decision + policy update.
- Confirm DTO projections and mock data are current before merging.

## Rationale
Screens are the primary consumer of DTO projections. Enforcing the Screen Workflow guarantees consistency with architecture rules and documentation-first mandates.

## Enforcement
- Use the Screen Workflow checklist before completing edits.
- Block PRs that touch these paths without following the workflow steps.

## Notes
This glob relies on `delphi-ai/workflows/flutter/create-screen-method.md`. Update the workflow if new screen patterns emerge.
