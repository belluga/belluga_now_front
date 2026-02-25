---
trigger: model_decision
description: "When working on routes, screens, repositories, or domain changes that impact contracts."
---

## Rule
If a task touches routes, screens, repositories, or domain models:
- Load and apply `foundation_documentation/policies/scope_subscope_governance.md` as canonical ownership source.
- Update `foundation_documentation/modules/` and `foundation_documentation/screens/` to reflect new flows/routes and UI behaviors.
- Ensure route/screen/module docs explicitly declare `EnvironmentType`, main scope, and subscope (when applicable).
- Forbid undefined subscopes or ambiguous scope statements; require explicit decision + policy update before any new subscope.
- Sync DTO/mock payloads with `foundation_documentation/screens/prototype_data.md` and related roadmap entries (`foundation_documentation/mock_roadmap.md`).
- Align domain vocabulary with `foundation_documentation/domain_entities_sections/*` and refresh summaries in `domain_entities.md` when fields change.
- Update `foundation_documentation/system_roadmap.md`, backlog, and submodule summaries with new API/contract work; ensure submodule hashes are noted when relevant.
- Notify downstream teams by recording roadmap deltas before code merges.
 - Treat `web-app` as derived/compiled: route test sources are source-owned and synced by build tooling; direct `web-app` test authoring is not authoritative.

## Rationale
Foundation docs are the contract source for all stacks. Keeping them synchronized with route/screen/repo/domain changes prevents drift and preserves traceability.

## Enforcement
- Trigger this rule whenever route/screen/repo/domain work is requested.
- Block merges lacking corresponding foundation doc updates or roadmap/submodule summary notes.

## Notes
Apply stack-specific rules (Flutter/Laravel glob rules) alongside this sync rule to ensure code and documentation stay in lockstep.

Also apply the TODO-Driven Execution Rule (`rules/docker/shared/todo-driven-execution-model-decision.md`) so tactical TODOs define scope and decisions before implementation begins.
