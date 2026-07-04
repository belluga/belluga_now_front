import 'package:belluga_form_validation/belluga_form_validation.dart';
import 'package:belluga_now/presentation/tenant_admin/events/models/tenant_admin_event_form_validation_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'maps place_ref.id backend errors into the location validation group',
    () {
      final state = tenantAdminEventFormValidationConfig.resolveFailure(
        FormValidationFailure(
          statusCode: 422,
          message: 'The given data was invalid.',
          fieldErrors: <String, List<String>>{
            'place_ref.id': <String>['Host físico inválido.'],
          },
        ),
      );

      expect(
        state.errorsForGroup(TenantAdminEventFormValidationTargets.location),
        <String>['Host físico inválido.'],
      );
      expect(state.errorsForGlobal(), isEmpty);
      expect(
        state.firstInvalidTargetId,
        TenantAdminEventFormValidationTargets.location,
      );
    },
  );

  test(
    'maps deeply nested location backend errors into the location group',
    () {
      final state = tenantAdminEventFormValidationConfig.resolveFailure(
        FormValidationFailure(
          statusCode: 422,
          message: 'The given data was invalid.',
          fieldErrors: <String, List<String>>{
            'location.geo.coordinates.0': <String>['Longitude inválida.'],
          },
        ),
      );

      expect(
        state.errorsForGroup(TenantAdminEventFormValidationTargets.location),
        <String>['Longitude inválida.'],
      );
      expect(state.errorsForGlobal(), isEmpty);
    },
  );

  test(
    'maps root event_parties backend errors into the related profiles group',
    () {
      final state = tenantAdminEventFormValidationConfig.resolveFailure(
        FormValidationFailure(
          statusCode: 422,
          message: 'The given data was invalid.',
          fieldErrors: <String, List<String>>{
            'event_parties.0.party_ref_id': <String>[
              'Related account profile was not found.',
            ],
          },
        ),
      );

      expect(
        state.errorsForGroup(
          TenantAdminEventFormValidationTargets.relatedProfiles,
        ),
        <String>['Related account profile was not found.'],
      );
      expect(state.errorsForGlobal(), isEmpty);
      expect(
        state.firstInvalidTargetId,
        TenantAdminEventFormValidationTargets.relatedProfiles,
      );
    },
  );

  test('maps root taxonomy_terms backend errors into the taxonomies group', () {
    final state = tenantAdminEventFormValidationConfig.resolveFailure(
      FormValidationFailure(
        statusCode: 422,
        message: 'The given data was invalid.',
        fieldErrors: <String, List<String>>{
          'taxonomy_terms': <String>['Taxonomias excederam o limite.'],
        },
      ),
    );

    expect(
      state.errorsForGroup(TenantAdminEventFormValidationTargets.taxonomies),
      <String>['Taxonomias excederam o limite.'],
    );
    expect(state.errorsForGlobal(), isEmpty);
  });

  test(
    'maps occurrence programming backend errors into the schedule group',
    () {
      final state = tenantAdminEventFormValidationConfig.resolveFailure(
        FormValidationFailure(
          statusCode: 422,
          message: 'The given data was invalid.',
          fieldErrors: <String, List<String>>{
            'occurrences.0.programming_items.0.place_ref.id': <String>[
              'Host da programação inválido.',
            ],
          },
        ),
      );

      expect(
        state.errorsForGroup(TenantAdminEventFormValidationTargets.schedule),
        <String>['Host da programação inválido.'],
      );
      expect(state.errorsForGlobal(), isEmpty);
      expect(
        state.firstInvalidTargetId,
        TenantAdminEventFormValidationTargets.schedule,
      );
    },
  );
}
