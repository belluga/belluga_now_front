---
trigger: always_on
description: Enforce Flutter architectural tenets across all tasks.
---

## Rule
Apply these Flutter architectural tenets on every task:
- Keep widgets pure UI; controllers own all state (`StreamValue`), UI controllers, side effects, and orchestration; widgets never touch repositories/infrastructure.
- Maintain feature-first structure (`tenant/<feature>/screens/...`) with controllers registered via ModuleScope/GetIt; controllers never accept `BuildContext`.
- Enforce DTO → Domain → Projection flow; DTOs never reach widgets, and projections expose UI-ready primitives only.
- Register routes via AutoRoute with guards (tenant shell/auth); use RouteModelResolver for hydration and keep route docs updated.
- Align repos/contracts with documented pagination/filtering expectations and mirror them in Laravel roadmaps.
- Analyzer/tests are mandatory: `fvm flutter analyze` must be clean; add targeted controller/widget tests when behaviour changes.

## Rationale
These tenets keep the Flutter client aligned with backend contracts, maintain purity of presentation, and prevent coupling DTOs to UI. AutoRoute governance and analyzer discipline guard navigation integrity and code quality.

## Enforcement
- Structure checks during PR/code review; ensure routes/controllers follow ModuleScope and AutoRoute rules.
- Analyzer: `fvm flutter analyze` must be clean.
- Tests: add/maintain unit/widget tests where impacted flows change.

## Notes
Reference `foundation_documentation/system_architecture_principles.md` Appendix A for full context. Update module/route docs when adding screens or routes.
