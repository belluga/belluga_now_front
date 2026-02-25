---
trigger: glob
description: Apply the route workflow whenever Flutter routing files are edited.
---

## Rule
Edits under `flutter-app/lib/**/routes/**` must follow the Route Workflow:
- Load and reference `foundation_documentation/policies/scope_subscope_governance.md` before defining ownership.
- Register new routes in AutoRoute with guards and ModuleScope wiring.
- Validate and document target ownership for each route (`EnvironmentType`, main scope, subscope when applicable).
- Use RouteModelResolver for hydration; update documentation (`screens/tenant_app.md`, route sections) accordingly.
- Do not create or imply undefined subscopes/folders; explicit decision + policy update is required first.
- Regenerate routes via build_runner and ensure analyzer passes.

## Rationale
Routing governs navigation and domain hydration. The workflow preserves RouteModelResolver discipline and documentation parity.

## Enforcement
- Run the Route Workflow steps before merging changes to these files.
- PRs should reference the updated docs and analyzer output.

## Notes
Workflow reference: `delphi-ai/workflows/flutter/create-route-method.md`. If a route starts elsewhere (e.g., doc-first updates), the glob serves as a safety net for code edits.
