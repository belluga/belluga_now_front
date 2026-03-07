import 'package:belluga_form_validation/belluga_form_validation.dart'
    as validation;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final config = validation.FormValidationConfig(
    formId: 'tenant_admin_account_create',
    bindings: <validation.FormValidationBinding>[
      validation.globalAny(
        const <String>['account', 'account_profile'],
      ),
      validation.field('profile_type'),
      validation.field('name'),
      validation.group('ownership_state', targetId: 'ownership'),
      validation.groupAny(
        const <String>['location', 'location.lat', 'location.lng'],
        targetId: 'location',
      ),
      validation.groupPattern('taxonomy_terms.*.*', targetId: 'taxonomies'),
    ],
  );

  test('resolves exact field and group bindings', () {
    final state = config.resolveFailure(
      validation.FormValidationFailure(
        statusCode: 422,
        message: 'Validation failed.',
        fieldErrors: const <String, List<String>>{
          'profile_type': <String>['Tipo obrigatorio.'],
          'ownership_state': <String>['Estado invalido.'],
        },
      ),
    );

    expect(state.errorForField('profile_type'), 'Tipo obrigatorio.');
    expect(state.errorsForGroup('ownership'), <String>['Estado invalido.']);
    expect(state.firstInvalidTargetId, 'profile_type');
  });

  test('normalizes bracket notation before matching wildcard bindings', () {
    final state = config.resolveFailure(
      validation.FormValidationFailure(
        statusCode: 422,
        message: 'Validation failed.',
        fieldErrors: const <String, List<String>>{
          'taxonomy_terms[0][value]': <String>['Termo invalido.'],
          'location[lat]': <String>['Latitude obrigatoria.'],
        },
      ),
    );

    expect(state.errorsForGroup('taxonomies'), <String>['Termo invalido.']);
    expect(state.errorsForGroup('location'), <String>['Latitude obrigatoria.']);
    expect(state.firstInvalidTargetId, 'location');
  });

  test('falls back unmapped keys to global and emits debug diagnostic', () {
    final diagnostics = <String>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        diagnostics.add(message);
      }
    };
    addTearDown(() {
      debugPrint = originalDebugPrint;
    });

    final state = config.resolveFailure(
      validation.FormValidationFailure(
        statusCode: 422,
        message: 'Validation failed.',
        fieldErrors: const <String, List<String>>{
          'unexpected.backend_key': <String>['Falha inesperada.'],
        },
      ),
    );

    expect(state.errorsForGlobal(), <String>['Falha inesperada.']);
    expect(state.firstInvalidTargetId, 'global');
    expect(diagnostics, isNotEmpty);
    expect(diagnostics.single, contains('unexpected.backend_key'));
  });

  test('binding declaration order defines first invalid target priority', () {
    final state = config.resolveFailure(
      validation.FormValidationFailure(
        statusCode: 422,
        message: 'Validation failed.',
        fieldErrors: const <String, List<String>>{
          'name': <String>['Nome obrigatorio.'],
          'profile_type': <String>['Tipo obrigatorio.'],
        },
      ),
    );

    expect(state.firstInvalidTargetId, 'profile_type');
  });
}
