---
description: Introduce a new Flutter domain aggregate with full architectural rigor—docs, value objects, projections, repository contracts, and DI wiring—aligned with our principles (backend-driven UI, DTO→Domain→Projection flow, feature-first structure).
---

# Method: Create Domain (Flutter)

## Purpose
Introduce a new Flutter domain aggregate with full architectural rigor—docs, value objects, projections, repository contracts, and DI wiring—aligned with the "Belluga Now Flutter Architecture Overview" principles (backend-driven UI, DTO→Domain→Projection flow, feature-first structure).

## Triggers
- A Flutter feature needs business logic/data not covered by an existing domain.
- Widgets/controllers are using DTOs or ad-hoc models that clearly represent a domain concept.
- Architecture docs call for a new aggregate or projection.

## Inputs
- Core instructions (`delphi-ai/main_instructions.md`, `system_architecture_principles.md`).
- Flutter architecture doc (`foundation_documentation/flutter_architecture.md`).
- Project-specific docs (`foundation_documentation/domain_entities.md`, module summaries/roadmap).
- Backend/API contracts for the new entity, if available.

## Procedure
1. **Run Persona Selection** – confirm we’re acting as Flutter Engineer.
2. **Document first**
   - Add/extend the domain entry in `foundation_documentation/domain_entities.md` (purpose, invariants, value objects).
   - Update the relevant module summary/system roadmap entry.
   - Append the persona impact to `foundation_documentation/persona_roadmaps.md` under the Flutter section.
3. **Scaffold the domain directory**
   - Create `lib/domain/<domain_name>/` with `value_objects/`, `projections/`, and entity file(s).
   - Implement the aggregate using ValueObjects (per Section 4 & 5 of the architecture doc). Add TODOs for attributes pending backend support.
4. **Define projections**
   - Place resumes/summaries in `lib/domain/<domain_name>/projections/`.
   - Ensure projections expose UI-ready primitives and enforce “projection diligence” (widgets/controllers never reformat data).
5. **Repository contract**
   - Create/extend `lib/domain/repositories/<domain>_repository_contract.dart` with domain-centric methods (no screen language). Add TODO comments if the method temporarily returns projections.
6. **Infrastructure mapping**
   - Add/update DTO mapper mixins under `lib/infrastructure/mappers/` to convert DTOs to ValueObjects.
   - Implement repository skeletons under `lib/infrastructure/repositories/`, keeping DTO knowledge inside the mapper mixin.
7. **Dependency injection**
   - Register repositories/services in `lib/application/router/modular_app/module_settings.dart` or feature module scopes, following Section 8 (GetIt) guidance.
8. **Controller/presentation cleanup**
   - Update controllers/widgets to depend on the new domain types and StreamValues. Remove DTO/view-model leaks; keep widgets pure UI.
9. **Verification**
   - Run `fvm flutter analyze` and, if relevant, unit tests for the new controller/use case.
10. **Document completion**
    - Reference this method in the work summary/commit so future agents know the domain was introduced via the standard workflow, and confirm persona roadmaps remain accurate.

## Outputs
- Updated domain + module documentation.
- `lib/domain/<domain_name>/` with entity, value objects, projections.
- Repository contract + infrastructure mapper/implementation registered in DI.
- Controllers/widgets consuming the domain types.
- TODO comments for deferred backend fields.

## Validation
- Analyzer/tests pass with the new domain wired.
- Documentation reflects the new concept (no dangling placeholders).
- DTOs remain confined to infrastructure; presentation imports only domain types.
