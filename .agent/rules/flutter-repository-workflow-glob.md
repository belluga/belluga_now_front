---
trigger: glob
description: Apply the repository workflow whenever Flutter repositories change.
---

## Rule
Edits in `flutter-app/lib/infrastructure/repositories/**` must run the Repository Workflow:
- Maintain DTO → Domain mapping discipline; no DTO leakage.
- Document pagination/filtering contracts and sync Laravel roadmap entries when APIs are implied.
- Update mock data/DTO docs before merging.

## Rationale
Repositories define how Flutter consumes domain contracts. The workflow keeps them aligned with documentation and backend expectations.

## Enforcement
- Execute the Repository Workflow steps for these paths.
- Require PR references to updated docs/roadmaps.

## Notes
Workflow reference: `delphi-ai/workflows/flutter/create-repository-method.md`.
