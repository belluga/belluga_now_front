---
trigger: always_on
description: Keep Flutter contracts aligned with domain entities and downstream teams.
---

## Rule
Maintain bidirectional contract alignment:
- Map every Flutter DTO/model to the governing entity in `foundation_documentation/domain_entities.md`; update the summaries when attributes change.
- When Flutter repositories alter pagination/filtering or new endpoints are implied, log the requirement in `foundation_documentation/system_roadmap.md` and the Laravel roadmap section so backend teams can plan matching APIs.
- Sync mock data with real contract expectations: regenerate JSON fixtures when DTOs change and notify Laravel via `submodule_laravel-app_summary.md` notes.
- Record integration dependencies (e.g., tenant app data, feature flags) in `project_mandate.md` or module docs before implementing them in Flutter.

## Rationale
Flutter is the lead consumer of the platform’s Core Business Entities. Keeping contracts synchronized avoids Laravel/API divergence and ensures every mock artifact is a dependable specification.

## Enforcement
- Reviews must verify DTO → entity mapping and roadmap updates accompany any repository or API-facing change.
- Reject commits that adjust mocks/DTOs without updating the corresponding roadmap/module documentation.
- Regularly compare `submodule_flutter-app_summary.md` against `.gitmodules` to ensure documentation reflects the submodule state.

## Notes
Use the persona roadmaps and module templates when a Flutter change creates backend work. Surface dependencies to Laravel/DevOps via roadmap entries as soon as they’re known.
