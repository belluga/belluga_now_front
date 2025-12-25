---
trigger: model_decision
description: "When defining realtime streams or pagination policies for app feeds."
---

## Rule
When adding or revising realtime feed behavior (SSE streams, delta updates, or pagination policies):
- Run `workflows/docker/realtime-delta-streams-method.md`.
- Keep list endpoints page-based and treat SSE as delta-only.
- Document SSE routes, event types, and resync behavior in `foundation_documentation/endpoints_mvp_contracts.md`.
- Ensure a roadmap entry exists for realtime delivery.

## Rationale
Realtime updates must complement, not replace, deterministic pagination. This keeps caching predictable while enabling live UI updates.

## Enforcement
- Block SSE additions that do not include a paginated list source of truth.
- Block pagination changes without updating the realtime workflow outputs.
