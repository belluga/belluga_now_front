---
trigger: glob
description: Apply the controller workflow whenever controller files are edited.
---

## Rule
When working inside `flutter-app/lib/presentation/**/controllers/**`, run the Controller Workflow:
- Controllers own StreamValue state, UI controllers, and orchestration; they never accept `BuildContext`.
- Register controllers via ModuleScope/GetIt and document responsibilities.
- Ensure analyzer/tests cover new behaviour.

## Rationale
Controllers enforce the separation between UI and domain logic. The workflow keeps every controller aligned with architecture tenets.

## Enforcement
- Run the Controller Workflow checklist for any edits to these paths.
- PRs must show analyzer/test evidence when controller logic changes.

## Notes
Workflow reference: `delphi-ai/workflows/flutter/create-controller-method.md`.
