import 'package:belluga_form_validation/belluga_form_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final config = FormValidationConfig(
    formId: 'account_create',
    bindings: <FormValidationBinding>[
      field('name'),
      groupAny(
        const <String>['location', 'location.lat', 'location.lng'],
        targetId: 'location',
      ),
      globalAny(const <String>['account']),
    ],
  );

  test('replaceWithResolved publishes local validation snapshot', () {
    final adapter = FormValidationControllerAdapter(config: config);

    adapter.replaceWithResolved(
      fieldErrors: const <String, List<String>>{
        'name': <String>['Nome obrigatorio.'],
      },
      groupErrors: const <String, List<String>>{
        'location': <String>['Localizacao obrigatoria.'],
      },
    );

    expect(adapter.state.errorForField('name'), 'Nome obrigatorio.');
    expect(
      adapter.state.errorsForGroup('location'),
      <String>['Localizacao obrigatoria.'],
    );
    expect(adapter.state.firstInvalidTargetId, 'name');
  });

  test('clear operations remove only the targeted validation slice', () {
    final adapter = FormValidationControllerAdapter(config: config);

    adapter.replaceWithResolved(
      fieldErrors: const <String, List<String>>{
        'name': <String>['Nome obrigatorio.'],
      },
      groupErrors: const <String, List<String>>{
        'location': <String>['Localizacao obrigatoria.'],
      },
    );
    adapter.clearField('name');

    expect(adapter.state.errorForField('name'), isNull);
    expect(
      adapter.state.errorsForGroup('location'),
      <String>['Localizacao obrigatoria.'],
    );
    expect(adapter.state.firstInvalidTargetId, 'location');
  });

  test('applyFailure replaces previous validation snapshot', () {
    final adapter = FormValidationControllerAdapter(config: config);

    adapter.replaceWithResolved(
      fieldErrors: const <String, List<String>>{
        'name': <String>['Nome obrigatorio.'],
      },
    );
    adapter.applyFailure(
      FormValidationFailure(
        statusCode: 422,
        message: 'Validation failed.',
        fieldErrors: const <String, List<String>>{
          'location.lat': <String>['Latitude obrigatoria.'],
        },
      ),
    );

    expect(adapter.state.errorForField('name'), isNull);
    expect(
      adapter.state.errorsForGroup('location'),
      <String>['Latitude obrigatoria.'],
    );
    expect(adapter.state.firstInvalidTargetId, 'location');
  });
}
