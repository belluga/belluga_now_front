import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_profiles_response_decoder.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_profile_type_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tenant admin profile type transport', () {
    test('parses canonical visual payload for account profile types', () {
      final dto = TenantAdminProfileTypeDTO.fromJson({
        'type': 'restaurant',
        'label': 'Restaurant',
        'labels': {'singular': 'Restaurant', 'plural': 'Restaurants'},
        'allowed_taxonomies': const ['cuisine'],
        'visual': {
          'mode': 'icon',
          'icon': 'restaurant',
          'color': '#EB2528',
          'icon_color': '#FFFFFF',
        },
      });

      final definition = dto.toDomain();

      expect(definition.label, 'Restaurant');
      expect(definition.pluralLabel, 'Restaurants');
      expect(definition.visual?.mode, TenantAdminPoiVisualMode.icon);
      expect(definition.visual?.icon, 'restaurant');
      expect(definition.visual?.color, '#EB2528');
      expect(definition.visual?.iconColor, '#FFFFFF');
    });

    test(
      'falls back to legacy poi_visual without canonical visual payload',
      () {
        final dto = TenantAdminProfileTypeDTO.fromJson({
          'type': 'artist',
          'label': 'Artist',
          'allowed_taxonomies': const [],
          'poi_visual': {'image_source': 'avatar'},
        });

        final definition = dto.toDomain();

        expect(definition.visual?.mode, TenantAdminPoiVisualMode.image);
        expect(
          definition.visual?.imageSource,
          TenantAdminPoiVisualImageSource.avatar,
        );
      },
    );

    test('parses canonical type_asset image payload', () {
      final dto = TenantAdminProfileTypeDTO.fromJson({
        'type': 'restaurant',
        'label': 'Restaurant',
        'allowed_taxonomies': const [],
        'visual': {
          'mode': 'image',
          'image_source': 'type_asset',
          'image_url':
              'https://tenant.test/api/v1/media/account-profile-types/type-1/type_asset?v=123',
        },
        'type_asset_url':
            'https://tenant.test/api/v1/media/account-profile-types/type-1/type_asset?v=123',
      });

      final definition = dto.toDomain();

      expect(definition.visual?.mode, TenantAdminPoiVisualMode.image);
      expect(
        definition.visual?.imageSource,
        TenantAdminPoiVisualImageSource.typeAsset,
      );
      expect(
        definition.visual?.imageUrl,
        'https://tenant.test/api/v1/media/account-profile-types/type-1/type_asset?v=123',
      );
    });

    test(
      'decodes backend-owned definitions, typed values, parameters, and resources',
      () {
        final definitions = tenantAdminCapabilityDefinitionsFromRaw([
          _booleanDefinition('is_favoritable', 'relationships'),
          {
            'key': 'location_policy',
            'domain': 'location',
            'value_type': 'enum',
            'default_value': 'optional',
            'fail_closed_value': 'disabled',
            'allowed_values': ['disabled', 'optional', 'required'],
            'parameters': const [],
            'resources': const {},
          },
          {
            'key': 'has_gallery',
            'domain': 'profile_content',
            'value_type': 'boolean',
            'default_value': false,
            'fail_closed_value': false,
            'parameters': [
              {
                'key': 'max_groups',
                'value_type': 'integer',
                'default_value': 6,
                'fail_closed_value': 0,
                'validations': [
                  {'rule': 'min', 'value': 0},
                  {'rule': 'max', 'value': 20},
                ],
              },
            ],
            'resources': {
              'gallery_groups': {
                'operations': [
                  {'key': 'create', 'ability': 'account-users:update'},
                  {'key': 'reorder', 'ability': 'account-users:update'},
                ],
              },
            },
          },
        ]);

        final dto = TenantAdminProfileTypeDTO.fromJson({
          'type': 'venue',
          'label': 'Venue',
          'allowed_taxonomies': const [],
          'capability_revision': 12,
          'capabilities': {
            'is_favoritable': _resolved(true),
            'location_policy': _resolved('required'),
            'has_gallery': _resolved(true, parameters: {'max_groups': 8}),
          },
        }, capabilityDefinitions: definitions);

        final definition = dto.toDomain();
        final galleryDefinition = definition.capabilityDefinitions.singleWhere(
          (item) => item.key == 'has_gallery',
        );

        expect(definition.capabilityRevision, 12);
        expect(
          definition.capabilities.isEnabled(_text('is_favoritable')),
          isTrue,
        );
        expect(definition.capabilities.locationPolicy, 'required');
        expect(definition.capabilities.isEnabled(_text('has_gallery')), isTrue);
        expect(
          definition.capabilities.parameterValue(
            _text('has_gallery'),
            _text('max_groups'),
          ),
          8,
        );
        expect(galleryDefinition.domain, 'profile_content');
        expect(galleryDefinition.parameters.single.validations.length, 2);
        expect(galleryDefinition.resources.single.key, 'gallery_groups');
        expect(
          galleryDefinition.resources.single.operations.map(
            (operation) => operation.key,
          ),
          ['create', 'reorder'],
        );
      },
    );

    test(
      'fails closed without reconstructing local defaults or dependencies',
      () {
        final definitions = tenantAdminCapabilityDefinitionsFromRaw([
          _booleanDefinition('is_queryable', 'relationships'),
          _booleanDefinition('is_publicly_discoverable', 'visibility'),
          _booleanDefinition('is_favoritable', 'relationships'),
        ]);

        final dto = TenantAdminProfileTypeDTO.fromJson({
          'type': 'artist',
          'label': 'Artist',
          'allowed_taxonomies': const [],
          'capabilities': {
            'is_queryable': _resolved(false),
            'is_publicly_discoverable': _resolved(true),
            'is_favoritable': _resolved('true'),
            'unknown_client_inventory_key': _resolved(true),
          },
        }, capabilityDefinitions: definitions).toDomain();

        expect(dto.capabilities.isEnabled(_text('is_queryable')), isFalse);
        expect(
          dto.capabilities.isEnabled(_text('is_publicly_discoverable')),
          isTrue,
        );
        expect(dto.capabilities.isEnabled(_text('is_favoritable')), isFalse);
        expect(dto.capabilities.entries, hasLength(3));
        expect(
          dto.capabilities.valueFor(_text('unknown_client_inventory_key')),
          isNull,
        );
      },
    );

    test(
      'keeps configured and effective values distinct and receives creation values from backend',
      () {
        final response = {
          'capability_definitions': [
            _booleanDefinition('is_queryable', 'relationships'),
            _booleanDefinition('is_map_poi_enabled', 'location'),
          ],
          'capability_creation_configuration': {
            'is_queryable': {'value': true, 'parameters': {}},
            'is_map_poi_enabled': {'value': false, 'parameters': {}},
          },
          'data': [
            {
              'type': 'venue',
              'label': 'Venue',
              'allowed_taxonomies': const [],
              'capabilities': {
                'is_queryable': _resolved(true),
                'is_map_poi_enabled': {
                  'configured': {'value': true, 'parameters': {}},
                  'effective': {'value': false, 'parameters': {}},
                },
              },
            },
          ],
        };

        final type = const TenantAdminAccountProfilesResponseDecoder()
            .decodeProfileTypeList(response)
            .single
            .toDomain();

        expect(type.capabilities.configuredIsMapPoiEnabled, isTrue);
        expect(type.capabilities.isMapPoiEnabled, isFalse);
        expect(
          type.capabilityCreationConfiguration.isEnabled(_text('is_queryable')),
          isTrue,
        );
      },
    );
  });
}

Map<String, dynamic> _booleanDefinition(String key, String domain) => {
  'key': key,
  'domain': domain,
  'value_type': 'boolean',
  'default_value': false,
  'fail_closed_value': false,
  'parameters': const [],
  'resources': const {},
};

TenantAdminRequiredTextValue _text(String value) =>
    TenantAdminRequiredTextValue()..parse(value);

Map<String, dynamic> _resolved(
  Object? value, {
  Map<String, int> parameters = const {},
}) => {
  'configured': {'value': value, 'parameters': parameters},
  'effective': {'value': value, 'parameters': parameters},
};
