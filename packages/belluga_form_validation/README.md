# belluga_form_validation

Internal reusable Flutter package for Belluga form validation.

## Scope

This package standardizes how Belluga Flutter forms render and manage validation. It is intentionally transport-agnostic.

- Repositories/infrastructure parse backend `422` responses.
- Controllers own one validation `StreamValue` per form.
- Screens render validation through package builders/widgets.

The canonical architecture contract still lives in:

- `foundation_documentation/modules/flutter_client_experience_module.md`
- `foundation_documentation/modules/tenant_admin_module.md`
- `foundation_documentation/screens/modulo_tenant_admin.md`

This package is the implementation surface for those contracts.

## Target Kinds

- `field`
- `group`
- `global`

## Binding Model

Each form declares one ordered `FormValidationConfig`.

- Binding declaration order is also invalid-target priority.
- V1 matching supports exact keys and wildcard/glob patterns.
- Keys are normalized narrowly for matching:
  - `taxonomy_terms[0].value` -> `taxonomy_terms.0.value`
  - `location[lat]` -> `location.lat`
- Unmapped keys fall back to `global` and emit a debug diagnostic in non-release builds.

Example:

```dart
final accountCreateValidationConfig = FormValidationConfig(
  formId: 'tenant_admin_account_create',
  bindings: [
    globalAny(['account', 'account_profile']),
    field('profile_type'),
    field('name'),
    group('ownership_state', targetId: 'ownership'),
    groupAny(
      ['location', 'location.lat', 'location.lng'],
      targetId: 'location',
    ),
    groupPattern('taxonomy_terms.*.*', targetId: 'taxonomies'),
    field('bio'),
    field('content'),
    groupAny(['avatar', 'cover'], targetId: 'media'),
  ],
);
```

## Controller Integration

Own one `FormValidationControllerAdapter` per form.

```dart
final createValidationController = FormValidationControllerAdapter(
  config: accountCreateValidationConfig,
);
```

Use it to:

- apply backend validation failures,
- replace the whole validation snapshot with local errors,
- clear one edited field/group/global target,
- expose the shared validation state to widgets.

## Rendering Hierarchy

- `field` -> `InputDecoration.errorText` (or field-local equivalent)
- `group` -> inline group validation widget
- `global` -> inline form-level validation summary/banner

`422` validation must not use snackbars.

## Anchors and Scroll

Use `FormValidationAnchors` plus `FormValidationAnchor` to register targets.
After applying a validation snapshot, the screen can call:

```dart
await anchors.scrollToFirstInvalidTarget(
  controller.createValidationController.state,
);
```

The helper waits until the next frame before calling `Scrollable.ensureVisible`.

## Clear-On-Edit Behavior

This package does not infer business rules.

- Features keep local validation rules.
- Features clear validation only after semantically meaningful value changes.
- New validation snapshots always replace the previous snapshot.

## Default Widgets

The package ships theme-dependent defaults for group/global validation.

- single message -> inline message
- multi-message -> collapsed summary + inline expand/collapse

Labels can be customized per adopter.

## First Adopter

The first adopter is Tenant Admin Account Create.

Related tactical TODOs:

- `foundation_documentation/todos/completed/TODO-flutter-forms-422-validation-wrapper.md`
- `foundation_documentation/todos/active/mvp_slices/TODO-account-profile-transaction-unified-create.md`

Broader form replacement remains a separate follow-up session.
