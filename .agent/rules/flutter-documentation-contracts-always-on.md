---
trigger: always_on
description: Document every Flutter change in foundation docs before code merges.
---

## Rule
Before touching Flutter code or mocks, update the authoritative documentation:
- Capture screen/flow changes in `foundation_documentation/screens/*.md` and reference DTO contracts in `modules/` where applicable.
- Record every mock payload/schema change in `foundation_documentation/screens/prototype_data.md` and refresh DTO notes in `foundation_documentation/domain_entities.md` when vocabulary evolves.
- Update module/roadmap entries (`mock_roadmap.md`, `system_roadmap.md`, `submodule_flutter-app_summary.md`) so Laravel and other consumers see the new scope before implementation starts.
- Reject any Flutter change whose documentation counterpart is missing or outdated.

## Rationale
Per Project Mandate P‑B6 (“Documentation Before Code”), the Flutter prototype defines launch contracts for Laravel and future clients. Keeping docs ahead of code prevents schema drift and maintains domain traceability.

## Enforcement
- PRs must link to the refreshed documentation sections.
- During reviews, block changes that modify DTOs, mocks, or UI flows without corresponding updates under `foundation_documentation/`.
- Use `tools/verify_context.sh` and roadmap checklists to ensure referenced files exist.

## Notes
If new domains are introduced, update `foundation_documentation/domain_entities_sections/*` first, then regenerate DTO/prototype data references. Include roadmap deltas in `system_roadmap.md` whenever APIs will be required later.
