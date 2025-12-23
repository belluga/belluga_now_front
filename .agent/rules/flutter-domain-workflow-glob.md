---
trigger: glob
description: Apply the domain modeling workflow whenever Flutter domain files change.
---

## Rule
When editing `flutter-app/lib/domain/**`, run the Domain Workflow:
- Reflect changes in `foundation_documentation/domain_entities_sections/*` before updating code.
- Ensure projections align with DTOs and update prototype data as needed.
- Record implications for repositories and APIs in the roadmap.

## Rationale
Domain models are the bridge between DTOs and screens. The workflow preserves single source of truth and contract traceability.

## Enforcement
- Execute the Domain Workflow steps for these files.
- Block PRs lacking documentation updates.

## Notes
Workflow reference: `delphi-ai/workflows/flutter/create-domain-method.md`.
