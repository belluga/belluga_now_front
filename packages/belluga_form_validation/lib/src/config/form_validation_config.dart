import 'package:flutter/foundation.dart';

import '../failures/form_validation_failure.dart';
import '../state/form_validation_state.dart';
import 'form_validation_binding.dart';

class FormValidationConfig {
  const FormValidationConfig({
    required this.formId,
    required this.bindings,
    this.fallbackGlobalTargetId = 'global',
  });

  final String formId;
  final List<FormValidationBinding> bindings;
  final String fallbackGlobalTargetId;

  FormValidationState resolveFailure(FormValidationFailure failure) {
    final fieldErrors = <String, List<String>>{};
    final groupErrors = <String, List<String>>{};
    final globalErrors = <String, List<String>>{};

    for (final entry in failure.fieldErrors.entries) {
      final normalizedKey = normalizeValidationKey(entry.key);
      final binding = _findBinding(normalizedKey);
      if (binding == null) {
        _emitUnmappedDiagnostic(
          rawKey: entry.key,
          normalizedKey: normalizedKey,
        );
        _appendMessages(globalErrors, fallbackGlobalTargetId, entry.value);
        continue;
      }
      if (binding.targetKind == FormValidationTargetKind.field) {
        _appendMessages(fieldErrors, binding.targetId, entry.value);
        continue;
      }
      if (binding.targetKind == FormValidationTargetKind.group) {
        _appendMessages(groupErrors, binding.targetId, entry.value);
        continue;
      }
      _appendMessages(globalErrors, binding.targetId, entry.value);
    }

    return buildResolvedState(
      fieldErrors: fieldErrors,
      groupErrors: groupErrors,
      globalErrors: globalErrors,
    );
  }

  FormValidationState buildResolvedState({
    Map<String, List<String>> fieldErrors = const <String, List<String>>{},
    Map<String, List<String>> groupErrors = const <String, List<String>>{},
    Map<String, List<String>> globalErrors = const <String, List<String>>{},
  }) {
    final frozenFieldErrors = _freeze(fieldErrors);
    final frozenGroupErrors = _freeze(groupErrors);
    final frozenGlobalErrors = _freeze(globalErrors);
    final firstInvalidTargetId = _resolveFirstInvalidTargetId(
      fieldErrors: frozenFieldErrors,
      groupErrors: frozenGroupErrors,
      globalErrors: frozenGlobalErrors,
    );
    return FormValidationState(
      fieldErrors: frozenFieldErrors,
      groupErrors: frozenGroupErrors,
      globalErrors: frozenGlobalErrors,
      firstInvalidTargetId: firstInvalidTargetId,
    );
  }

  FormValidationBinding? _findBinding(String normalizedKey) {
    for (final binding in bindings) {
      if (binding.matches(normalizedKey)) {
        return binding;
      }
    }
    return null;
  }

  String? _resolveFirstInvalidTargetId({
    required Map<String, List<String>> fieldErrors,
    required Map<String, List<String>> groupErrors,
    required Map<String, List<String>> globalErrors,
  }) {
    final presentTargetIds = <String>{
      ...fieldErrors.keys,
      ...groupErrors.keys,
      ...globalErrors.keys,
    };
    if (presentTargetIds.isEmpty) {
      return null;
    }

    final orderedTargetIds = <String>[];
    for (final binding in bindings) {
      if (!orderedTargetIds.contains(binding.targetId)) {
        orderedTargetIds.add(binding.targetId);
      }
    }
    if (!orderedTargetIds.contains(fallbackGlobalTargetId)) {
      orderedTargetIds.add(fallbackGlobalTargetId);
    }

    for (final targetId in orderedTargetIds) {
      if (presentTargetIds.contains(targetId)) {
        return targetId;
      }
    }
    return presentTargetIds.first;
  }

  void _emitUnmappedDiagnostic({
    required String rawKey,
    required String normalizedKey,
  }) {
    if (kReleaseMode) {
      return;
    }
    debugPrint(
      '[belluga_form_validation][$formId] '
      'Unmapped validation key "$rawKey" (normalized: "$normalizedKey"). '
      'Falling back to global target "$fallbackGlobalTargetId".',
    );
  }

  static void _appendMessages(
    Map<String, List<String>> target,
    String targetId,
    List<String> messages,
  ) {
    final current = target[targetId] ?? <String>[];
    final merged = <String>[...current];
    for (final message in messages) {
      final trimmed = message.trim();
      if (trimmed.isEmpty || merged.contains(trimmed)) {
        continue;
      }
      merged.add(trimmed);
    }
    if (merged.isNotEmpty) {
      target[targetId] = merged;
    }
  }

  static Map<String, List<String>> _freeze(Map<String, List<String>> source) {
    final result = <String, List<String>>{};
    for (final entry in source.entries) {
      final targetId = entry.key.trim();
      if (targetId.isEmpty) {
        continue;
      }
      final messages = entry.value
          .map((message) => message.trim())
          .where((message) => message.isNotEmpty)
          .toList(growable: false);
      if (messages.isEmpty) {
        continue;
      }
      result[targetId] = List<String>.unmodifiable(messages);
    }
    return Map<String, List<String>>.unmodifiable(result);
  }
}
