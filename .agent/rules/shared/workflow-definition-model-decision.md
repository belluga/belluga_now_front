---
trigger: model_decision
description: "When creating or updating a workflow/procedure."
---

## Rule
When defining or editing a workflow:
- Use `delphi-ai/templates/workflow_template.md` as the scaffold.
- Name files in kebab-case (no underscores) and include the template header fields exactly.
- Create or update the corresponding rule (glob/model_decision/manual) so the workflow is triggerable; reference the workflow path explicitly.
- Place stack-specific rules under the appropriate stack folder; shared rules go in `rules/docker/shared/` (symlinked to other stacks).
- Remove or archive obsolete workflows/rules together to avoid drift.

## Rationale
Workflows are only effective when triggered by rules. This rule keeps procedures consistent and ensures they’re callable by the agent in Codex CLI (and similar harnesses).

## Enforcement
- Block additions/edits that lack a matching rule or deviate from the template.
- Require PR reviewers to verify the rule ↔ workflow linkage.

## Notes
When adding a new workflow, also update AGENTS/instructions if the loading order or commands change.
