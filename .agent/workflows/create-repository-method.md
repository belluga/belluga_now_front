---
description: Establish domain-aligned data access for Flutter features, keeping DTO knowledge in infrastructure and enforcing the architecture mandates (Section 5 Data Flow, Section 8 DI).
---

# Method: Create Repository (Flutter)

## Purpose
Establish domain-aligned data access for Flutter features, keeping DTO knowledge in infrastructure and enforcing the architecture mandates (Section 5 Data Flow, Section 8 DI).

## Triggers
- A new Flutter domain requires persistence/read APIs.
- Existing repositories mix multiple aggregates or leak screen terminology.
- Backend contracts change, requiring new DTO mappers.

## Inputs
- Domain contract + projections (`lib/domain/**`).
- Architecture docs + backend DTO definitions.
- DI configuration files.

## Procedure
1. **Run Persona Selection** – confirm Flutter Engineer persona.
2. **Define domain contract**
   - Update/create `lib/domain/repositories/<name>_repository_contract.dart` using domain verbs (no “screen” references). Annotate temporary projection returns with TODOs if the full entity is pending.
3. **Design DTO mapper**
   - Implement/update `lib/infrastructure/mappers/<feature>_dto_mapper.dart` to translate DTOs → ValueObjects.
   - Keep slugging/formatting helpers inside the mapper to avoid leaks.
4. **Implement repository**
   - Add `lib/infrastructure/repositories/<name>_repository.dart` that mixes in the mapper and talks to `BackendContract` or the appropriate datasource.
   - Ensure no presentation imports appear.
5. **Dependency injection**
   - Register the repository in `module_settings.dart` or the relevant module scope via `registerLazySingleton` / `registerFactory`.
6. **Controller adoption**
   - Update controllers/services to depend on the contract (GetIt injection). Remove any direct DTO parsing.
7. **Documentation touch**
   - Note repository availability in module summaries/system roadmap if it unlocks new behavior.
   - Update the Flutter section of `foundation_documentation/persona_roadmaps.md` with the new capability or technical debt payoff.
8. **Verification**
   - Run `fvm flutter analyze`; add/re-run unit tests covering the repository/user of it.

## Outputs
- Repository contract + implementation files.
- DTO mapper mixins covering new conversions.
- DI registration + controller usage.
- Documentation/roadmap notes if scope changed.

## Validation
- Analyzer/tests pass.
- Controllers/widgets import only the contract, not DTOs.
- DTO handling remains infrastructure-only.
